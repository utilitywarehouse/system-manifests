function init()
	-- Initialize the global Data table
	Data = {
		inactive = {
			component_received_events_total = 0,
			component_received_event_bytes_total = 0,
		},
		active = {
			component_received_events_total = {},
			component_received_event_bytes_total = {},
		},
	}
end

function on_event(event, emit)
	if not pcall(upsert_metric, event) then
		emit(generate_log("ERROR on upsert_metric", event))
		error() -- delegates on vector generating and increasing the error metric
	end
end

function on_timer(emit)
	if not pcall(emit_metrics, emit) then
		emit(generate_log("ERROR on emit_metrics", Data))
		error() -- delegates on vector generating and increasing the error metric
	end
end

function upsert_metric(event)
	-- ensure that we don't mess with custom kube sources like "kubernetes_events"
	if event.metric.tags.component_id ~= "kubernetes_logs" then
		error()
	end

	local name = event.metric.name
	local ns = event.metric.tags.pod_namespace
	local pod = event.metric.tags.pod_name
	local value = event.metric.counter.value

	-- ensure that the metric type hasn't changed
	if event.metric.kind ~= "absolute" then
		error()
	end

	Data["active"][name][ns .. "__" .. pod] = value
end

function emit_metrics(emit)
	cleanup_inactive_pods()
	emit(generate_metric("component_received_events_total"))
	emit(generate_metric("component_received_event_bytes_total"))
end

function cleanup_inactive_pods()
	active = active_pods()

	for metric, pods in pairs(Data.active) do
		for pod, value in pairs(pods) do
			if not active[pod] then
				Data["inactive"][metric] = Data["inactive"][metric] + value
				Data["active"][metric][pod] = nil
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

function generate_metric(name)
	local active = 0
	for _, value in pairs(Data["active"][name]) do
		active = active + tostring(value)
	end
	local total = active + Data["inactive"][name]
	return {
		metric = {
			name = name,
			namespace = "vector",
			tags = {
				component_id = "kubernetes_logs",
				component_kind = "source",
				component_type = "kubernetes_logs",
			},
			kind = "absolute",
			counter = {
				value = total,
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
