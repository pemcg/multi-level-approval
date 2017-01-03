$evm.log("info", "Checking for auto_approval")
approval_type = $evm.object['approval_type'].downcase
case approval_type
when 'auto'
  $evm.log("info", "AUTO-APPROVING")
  $evm.root["miq_request"].approve("admin", "Auto-Approved")
when 'multi-level'
  msg = "Sending for first level of approval"
  $evm.log("info", msg)
  $evm.root['ae_result'] = 'error'
  $evm.object['reason'] = msg
else
  $evm.log("error", "Approval Type must be either 'auto' or 'multi-level'")
  exit MIQ_ABORT
end
