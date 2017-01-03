#
# Description: This method is used to email the requester that the Service request was not auto-approved
#

# $evm.root['miq_request'].options[:dialog] = {"dialog_approval_level"=>"multi", "dialog_service_name"=>"Blah", "dialog_tag_0_environment"=>"prod", "dialog_option_1_guid"=>"57fac1f8-a100-11e6-b8c8-001a4aa0151a", "dialog_option_1_vm_name"=>"blah01", "dialog_option_1_flavor"=>"01_small", "dialog_option_1_volume_1_size"=>"0", "dialog_tag_1_flex_monitor"=>"false", "dialog_tag_1_flex_maximum"=>"1", "dialog_option_1_number_of_vms"=>"1"} 

def send_mail(to, from, subject, body)
  $evm.log(:info, "Sending email to #{to} from #{from} subject: #{subject}")
  $evm.execute(:send_email, to, from, subject, body)
end

def requester
  @miq_request.requester
end

def signature
  $evm.object['signature']
end

def reason
  @miq_request.reason
end

def approver_href(appliance)
  body = "<a href='https://#{appliance}/miq_request/show/#{@miq_request.id}'"
  body += ">https://#{appliance}/miq_request/show/#{@miq_request.id}</a>"
  body
end

def approver_text(appliance, requester_email)
  body = "Approver, "
  body += "<br>A Service request received from #{requester_email} is pending."
  body += "<br><br>Approvers notes: #{@miq_request.reason}"
  body += "<br><br>For more information you can go to: "
  body += approver_href(appliance)
  body += "<br><br> Thank you,"
  body += "<br> #{signature}"
  body
end

def dialog_options(options_hash)
  options = []
  options_hash.each do |option, value|
    next if /(^tag|^dialog_tag|^.*guid.*$).*/ =~ option
    options << {option.to_s.sub(/^dialog_option_\d+_/, '').sub(/^dialog_/, '') => value}
  end
  options
end

def dialog_tags(options_hash)
  tags = []
  options_hash.each do |option, value|
    next unless /(^tag|^dialog_tag).*/ =~ option
    tags << {option.to_s.sub(/^dialog_tag_\d+_/, '') => value}
  end
  tags
end

def approver_text_multi_level(appliance, requester_email)
  body = "<br>"
  body += "<br>A Service request received from #{requester_email} is pending, and you are the first stage approver."
  body += "<br><br>Request details: "
  if @dialog_options_hash.key?('dialog_service_name')
    body += "<br><br>&nbsp;&nbsp;Service description: #{@dialog_options_hash['dialog_service_name']}"
  else
    body += "<br><br>&nbsp;&nbsp;Service description: #{@miq_request.description}"
  end
  body += "<br><br>&nbsp;&nbsp;Service options selected: "
  dialog_options(@dialog_options_hash).each do |option| 
    key, value = option.flatten
    body += "<br>&nbsp;&nbsp;&nbsp;&nbsp;#{key}: #{value}"
  end
  body += "<br><br>&nbsp;&nbsp;Service tags selected: "
  dialog_tags(@dialog_options_hash).each do |option|
    key, value = option.flatten
    body += "<br>&nbsp;&nbsp;&nbsp;&nbsp;#{key}: #{value}"
  end
  body += "<br><br>To approve or deny this request please go to: "
  body += approver_href(appliance)
  body += "<br><br> Thank you,"
  body += "<br> #{signature}"
  body
end

def requester_email_address
  owner_email = @miq_request.options.fetch(:owner_email, nil)
  email = requester.email || owner_email || $evm.object['to_email_address']
  $evm.log(:info, "To email: #{email}")
  email
end

def email_approver(appliance)
  $evm.log(:info, "Approver email logic starting")
  requester_email = requester_email_address
  to = $evm.object['to_email_address']
  from = $evm.object['from_email_address']
  subject = "Request ID #{@miq_request.id} - Service request needs approving"
  if @dialog_options_hash['dialog_approval_level'] == 'multi'
    send_mail(to, from, subject, approver_text_multi_level(appliance, requester_email))
  else
    send_mail(to, from, subject, approver_text(appliance, requester_email))
  end
end

def requester_href(appliance)
  body = "<a href='https://#{appliance}/miq_request/show/#{@miq_request.id}'>"
  body += "https://#{appliance}/miq_request/show/#{@miq_request.id}</a>"
end

def requester_text(appliance)
  body = "Hello, "
  body += "<br><br>Please review your Request and wait for approval from an Administrator."
  body += "<br><br>To view this Request go to: "
  body += requester_href(appliance)
  body += "<br><br> Thank you,"
  body += "<br> #{signature}"
end

def email_requester(appliance)
  $evm.log(:info, "Requester email logic starting")
  to = requester_email_address
  from = $evm.object['from_email_address']
  subject = "Request ID #{@miq_request.id} - Your Service Request was not Auto-Approved"

  send_mail(to, from, subject, requester_text(appliance))
end

@miq_request = $evm.root['miq_request']
@dialog_options_hash = @miq_request.options[:dialog]
$evm.log(:info, "miq_request id: #{@miq_request.id} approval_state: #{@miq_request.approval_state}")
$evm.log(:info, "options: #{@miq_request.options.inspect}")

service_template = $evm.vmdb(@miq_request.source_type, @miq_request.source_id)
$evm.log(:info, "service_template id: #{service_template.id} service_type: #{service_template.service_type}")
$evm.log(:info, "description: #{service_template.description} services: #{service_template.service_resources.count}")

appliance = $evm.root['miq_server'].ipaddress

#email_requester(appliance)
email_approver(appliance)
