request_id = $evm.get_state_var(:automation_request_id)
$evm.log(:info, "Retrieved automation request ID: #{request_id}")
request = $evm.vmdb(:automation_request, request_id) rescue nil
if request.nil?
  $evm.log(:error, "Can't find request with ID: #{request_id}")
  $evm.root['ae_result'] = 'error'
  exit MIQ_ERROR
else
  if request.miq_request_tasks.length.zero?
    $evm.root['ae_result']         = 'retry'
    $evm.root['ae_retry_interval'] = '1.minute'
    exit MIQ_OK
  else
    task = request.miq_request_tasks.first
  end
  task_status = task['status']
  result = task.statemachine_task_status

  $evm.log(:info, "ServiceProvision_Intermediate check_progress returned <#{result}> for state <#{task.state}> and status <#{task_status}>")

  case result
  when 'error'
    $evm.root['ae_result'] = 'error'
    reason = $evm.root['service_template_provision_task'].message
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
