function init()
	-- Initialize the global LastValue table
	LastValue = {
		component_received_events_total = {},
		component_received_event_bytes_total = {},
	}
	-- since vector by default keeps these metrics, global config flag `
	-- expire_metrics_secs` must be set
	-- this interval should be higher then `expire_metrics_secs`
	ExpireMetricSecs = 600
end

function on_event(event, emit)
	--TODO: remove
	-- emit(event)

	local status, err = pcall(process_event, event, emit)
	if not status then
		emit(generate_log("ERROR on process_event" .. err, event))
		error() -- delegates on vector generating and increasing the error metric
	end
end

function on_timer(emit)
	local status, err = pcall(cleanup_inactive_metrics, emit)
	if not status then
		emit(generate_log("ERROR on cleanup_inactive_metrics" .. err, LastValue))
		error() -- delegates on vector generating and increasing the error metric
	end
end

function process_event(event, emit)
	-- ensure that the metric type hasn't changed
	if event.metric.kind ~= "absolute" then
		emit(generate_log("ERROR only absolute events can be aggregated", event))
		error()
	end

	local name = event.metric.name
	local ns = event.metric.tags.pod_namespace or ""
	local pod = event.metric.tags.pod_name or ""
	local newValue = event.metric.counter.value
	local key = ns .. "__" .. pod

	if ns == "" then
		emit(generate_log("ERROR empty namespace not allowed", event))
		error()
	end

	if pod == "" then
		emit(generate_log("ERROR empty pod name not allowed", event))
		error()
	end

	if LastValue[name][key] == nil then
		LastValue[name][key] = { value = 0, updatedAt = os.time() }
	end

	local inc = newValue - LastValue[name][key].value

	if inc > 0 then
		emit(generate_metric(name, ns, inc))
	elseif inc < 0 then
		emit(generate_log("ERROR adjusting negative diff inc:" .. inc .. ", old:" .. table_to_json(LastValue[name][key]),
			event))
		-- since metrics are counters if new value is < old value then we can
		-- assume metrics has been expired on vector end.
		-- hence we can take newValue as "new" initial value
		emit(generate_metric(name, ns, newValue))
	end

	-- since vector by default persists inactive metrics, global config flag
	-- `expire_metrics_secs` must be set to expire stale metrics.
	-- since vector will remove these metrics based on last updated time
	-- script needs to maintain its own timestamp for clean up
	if LastValue[name][key].value ~= newValue then
		LastValue[name][key].value = newValue
		LastValue[name][key].updatedAt = os.time()
	end
end

function cleanup_inactive_metrics(emit)
	local currentTime = os.time()

	for metric, pods in pairs(LastValue) do
		for pod, _ in pairs(pods) do
			if (currentTime - LastValue[metric][pod].updatedAt) > ExpireMetricSecs then
				LastValue[metric][pod] = nil
			end
		end
	end
end

function generate_log(message, payload)
	payload = payload or {}
	local json = '{"timestamp":"'
		.. os.date("%Y-%m-%dT%H:%M:%S")
		.. '","message":" [metrics.lua] '
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
	if t == nil then
		return "null"
	end

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
