$evm.log("info", "Checking for auto_approval")
automation_request = $evm.root['automation_request']
if automation_request.options.key?(:attrs)
  if automation_request.options[:attrs].key?('dialog_options_hash')
    dialog_options_hash = automation_request.options[:attrs]['dialog_options_hash'][0]
  end
end
approval_level = dialog_options_hash[:approval_level] rescue 'none'
case approval_level
when 'none', 'auto'
  $evm.log("info", "AUTO-APPROVING")
  $evm.root["miq_request"].approve("admin", "Auto-Approved")
when 'multi'
  msg = "Sending for second level of approval"
  $evm.log("info", msg)
  $evm.root['ae_result'] = 'error'
  $evm.object['reason'] = msg
else
  $evm.log("error", "Unrecognised approval level")
  exit MIQ_ABORT
end
