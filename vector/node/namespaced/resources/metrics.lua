function init()
	-- Initialize the global LastValue table
	LastValue = {
		component_received_events_total = {},
		component_received_event_bytes_total = {},
	}
end

function on_event(event, emit)
	--TODO: remove
	emit(event)
	if not pcall(process_event, event, emit) then
		emit(generate_log("ERROR on process_event", event))
		error() -- delegates on vector generating and increasing the error metric
	end
end

function on_timer(emit)
	if not pcall(cleanup_inactive_pods) then
		emit(generate_log("ERROR on cleanup_inactive_pods", LastValue))
		error() -- delegates on vector generating and increasing the error metric
	end
end

function process_event(event, emit)
	local name = event.metric.name
	local ns = event.metric.tags.pod_namespace
	local pod = event.metric.tags.pod_name
	local value = event.metric.counter.value

	-- ensure that the metric type hasn't changed
	if event.metric.kind ~= "absolute" then
		error()
	end

	local last_value = LastValue[name][ns .. "__" .. pod] or 0
	local inc = value - last_value

	emit(generate_metric(name, ns, inc))

	LastValue[name][ns .. "__" .. pod] = value
end

function cleanup_inactive_pods()
	active = active_pods()

	for metric, pods in pairs(LastValue) do
		for pod, _ in pairs(pods) do
			if not active[pod] then
				LastValue[metric][pod] = nil
			end
		end
	end
end

function active_pods()
	local ls_handle = io.popen("ls /var/log/containers")
	local containers
	if ls_handle then
		containers = ls_handle:read("*a")
		ls_handle:close()
	end

	local pods = {}
	for container in string.gmatch(containers, "[^\n]+") do
		local pod, ns = string.match(container, "([^_]+)_([^_]+)")
		local id = ns .. "__" .. pod
		pods[id] = true
	end
	return pods
end

function generate_log(message, payload)
	payload = payload or {}
	local json = '{"timestamp":"'
		.. os.date("%Y-%m-%dT%H:%M:%S")
		.. '","message":"'
		.. message
		.. '","payload":'
		.. table_to_json(payload)
		.. "}"

	return {
		log = {
			message = json,
			timestamp = os.date("!*t"),
		},
	}
end

function generate_metric(name, namespace, value)
	return {
		metric = {
			name = name,
			--TODO: change to vector
			namespace = "hh",
			tags = {
				component_id = "kubernetes_logs",
				component_kind = "source",
				component_type = "kubernetes_logs",
				pod_namespace = namespace,
			},
			kind = "incremental",
			counter = {
				value = value,
			},
			timestamp = os.date("!*t"),
		},
	}
end

function table_to_json(t)
	local contents = {}
	for key, value in pairs(t) do
		if type(value) == "table" then
			table.insert(contents, '"' .. key .. '"' .. ":" .. table_to_json(value))
		elseif "number" == type(value) then
			table.insert(contents, string.format('"%s":%s', key, value))
		elseif "string" == type(value) then
			table.insert(contents, string.format('"%s":"%s"', key, value))
		end
	end
	return "{" .. table.concat(contents, ",") .. "}"
end
