#
# Description: This method is used to email the requester that the automation request was not auto-approved
#

# $evm.root['automation_request'].options[:attrs] = {"dialog_options_hash"=>{0=>{:approval_level=>"multi", :dialog_approval_level=>"multi", :service_name=>"Test", :dialog_service_name=>"Test"}, 1=>{:guid=>"57ae878e-a100-11e6-b8c8-001a4aa0151a", :vm_name=>"testsrv010", :flavor=>"01_small", :volume_1_size=>"0", :number_of_vms=>"1"}}, "dialog_tags_hash"=>{0=>{:environment=>"dev"}, 1=>{:flex_monitor=>"false", :flex_maximum=>"1"}}, "service_id"=>35}   (type: Hash)

def send_mail(to, from, subject, body)
  $evm.log(:info, "Sending email to #{to} from #{from} subject: #{subject}")
  $evm.execute(:send_email, to, from, subject, body)
end

def requester
  @automation_request.requester
end

def signature
  $evm.object['signature']
end

def reason
  @automation_request.reason
end

def approver_href(appliance)
  body = "<a href='https://#{appliance}/miq_request/show/#{@automation_request.id}'"
  body += ">https://#{appliance}/miq_request/show/#{@automation_request.id}</a>"
  body
end

def approver_text(appliance, requester_email)
  body = "Approver, "
  body += "<br>An automation request received from #{requester_email} is pending."
  body += "<br><br>Approvers notes: #{@automation_request.reason}"
  body += "<br><br>For more information you can go to: "
  body += approver_href(appliance)
  body += "<br><br> Thank you,"
  body += "<br> #{signature}"
  body
end

def dialog_options(options_hash)
  options = []
  options_hash.each do |option, value|
    next if /^guid/ =~ option.to_s
    options << {option.to_s.sub(/^dialog_/, '') => value}
  end
  options.uniq!
end

def dialog_tags(tags_hash)
  tags = []
  tags_hash.each do |tag, value|
    tags << {tag.to_s.sub(/^dialog_tag_\d+_/, '') => value}
  end
  tags
end

def approver_text_multi_level(appliance, requester_email)
  body = "<br>"
  body += "<br>A Service request received from #{requester_email} is pending, and you are the second stage approver."
  body += "<br><br>Request details: "
  if @dialog_options_hash.key?(:dialog_service_name)
    body += "<br><br>&nbsp;&nbsp;Service description: #{@dialog_options_hash[:dialog_service_name]}"
  else
    body += "<br><br>&nbsp;&nbsp;Service description: #{@automation_request.description}"
  end
  body += "<br><br>&nbsp;&nbsp;Service options selected: "
  dialog_options(@dialog_options_hash).each do |option| 
    key, value = option.flatten
    body += "<br>&nbsp;&nbsp;&nbsp;&nbsp;#{key}: #{value}"
  end
  body += "<br><br>&nbsp;&nbsp;Service tags selected: "
  dialog_tags(@dialog_tags_hash).each do |tag|
    key, value = tag.flatten
    body += "<br>&nbsp;&nbsp;&nbsp;&nbsp;#{key}: #{value}"
  end
  body += "<br><br>To approve or deny this request please go to: "
  body += approver_href(appliance)
  body += "<br><br> Thank you,"
  body += "<br> #{signature}"
  body
end

def requester_email_address
  owner_email = @automation_request.options.fetch(:owner_email, nil)
  email = requester.email || owner_email || $evm.object['to_email_address']
  $evm.log(:info, "To email: #{email}")
  email
end

def email_approver(appliance)
  $evm.log(:info, "Approver email logic starting")
  requester_email = requester_email_address
  to = $evm.object['to_email_address']
  from = $evm.object['from_email_address']
  subject = "Request ID #{@automation_request.id} - Service request needs approving"
  if @dialog_options_hash[:dialog_approval_level] == 'multi'
    send_mail(to, from, subject, approver_text_multi_level(appliance, requester_email))
  else
    send_mail(to, from, subject, approver_text(appliance, requester_email))
  end
end

def requester_href(appliance)
  body = "<a href='https://#{appliance}/miq_request/show/#{@automation_request.id}'>"
  body += "https://#{appliance}/miq_request/show/#{@automation_request.id}</a>"
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
  subject = "Request ID #{@automation_request.id} - Your Automation Request was not Auto-Approved"

  send_mail(to, from, subject, requester_text(appliance))
end

@automation_request = $evm.root['automation_request']
global_options = @automation_request.options[:attrs]['dialog_options_hash'][0]
@dialog_options_hash = global_options.merge(@automation_request.options[:attrs]['dialog_options_hash'][1])
global_tags = @automation_request.options[:attrs]['dialog_tags_hash'][0]
@dialog_tags_hash = global_tags.merge(@automation_request.options[:attrs]['dialog_tags_hash'][1])
$evm.log(:info, "automation_request id: #{@automation_request.id} approval_state: #{@automation_request.approval_state}")
$evm.log(:info, "options: #{@automation_request.options.inspect}")

appliance = $evm.root['miq_server'].ipaddress

#email_requester(appliance)
email_approver(appliance)
