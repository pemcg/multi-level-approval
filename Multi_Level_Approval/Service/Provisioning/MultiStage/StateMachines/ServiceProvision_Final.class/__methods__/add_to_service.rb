$evm.log(:info, "Starting add_to_service")
request_ids = $evm.get_state_var(:provision_request_ids)
service_id = $evm.get_state_var(:service_id)
$evm.log(:info, "Found #{request_ids.length} request(s)")
request = $evm.vmdb(:miq_provision_request, request_ids.first) rescue nil
service = $evm.vmdb(:service, service_id) rescue nil
$evm.log(:info, "Request class: #{request.class}")
unless request.nil?
  task = request.miq_request_tasks.first
  vm = task.destination
  $evm.log(:info, "Adding #{vm.name} to #{service.name}")
  vm.add_to_service(service)
end
