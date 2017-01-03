request_ids = $evm.get_state_var(:provision_request_ids)
$evm.log(:info, "Found #{request_ids.length} request(s)")
request = $evm.vmdb(:miq_provision_request, request_ids.first) rescue nil
$evm.log(:info, "Request class: #{request.class}")
unless request.nil?
  if request.miq_request_tasks.length.zero?
    $evm.root['ae_result']         = 'retry'
    $evm.root['ae_retry_interval'] = '1.minute'
    exit MIQ_OK
  else
    task = request.miq_request_tasks.first
  end
  task_status = task['status']
  result = task.statemachine_task_status

  $evm.log(:info, "ServiceProvision_Final check_progress returned <#{result}> for state <#{task.state}> and status <#{task_status}>")

  case result
  when 'error'
    $evm.root['ae_result'] = 'error'
    reason = $evm.root['miq_provision'].message
    reason = reason[7..-1] if reason[0..6] == 'Error: '
    $evm.root['ae_reason'] = reason
  when 'retry'
    $evm.root['ae_result']         = 'retry'
    $evm.root['ae_retry_interval'] = '1.minute'
  when 'ok'
    # Bump State
    $evm.root['ae_result'] = 'ok'
  end
end
