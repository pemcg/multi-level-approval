#
# Description: This method Performs the following functions:
# 1. YAML load the Service Dialog Options from @task.get_option(:parsed_dialog_options))
# 2. Launch a create_automation_request
# Important - The dialog_parser automate method has to run prior to this in order to populate the dialog information.
#

def log_and_update_message(level, msg, update_message = false)
  $evm.log(level, "#{msg}")
  @task.message = msg if @task && (update_message || level == 'error')
end

def create_automation_request(dialog_options_hash, dialog_tags_hash)
  attrs = {}
  attrs['dialog_options_hash'] = dialog_options_hash
  attrs['dialog_tags_hash']    = dialog_tags_hash
  attrs['service_id']          = @service.id
  options = {}
  options[:namespace]     = $evm.object['next_namespace']
  options[:class_name]    = $evm.object['next_class']
  options[:instance_name] = $evm.object['next_instance']
  options[:user_id]       = $evm.root['user'].id
  options[:attrs]         = attrs
  auto_approve            = false
  request_id = $evm.execute('create_automation_request', options, $evm.root['user'].userid, auto_approve)
end

def remove_service
  log_and_update_message(:info, "Processing remove_service...", true)
  if @service
    log_and_update_message(:info, "Removing Service: #{@service.name} id: #{@service.id} due to failure")
    @service.remove_from_vmdb
  end
  log_and_update_message(:info, "Processing remove_service...Complete", true)
end

def yaml_data(option)
  @task.get_option(option).nil? ? nil : YAML.load(@task.get_option(option))
end

def parsed_dialog_information
  dialog_options_hash = yaml_data(:parsed_dialog_options)
  dialog_tags_hash = yaml_data(:parsed_dialog_tags)
  if dialog_options_hash.blank? && dialog_tags_hash.blank?
    log_and_update_message(:info, "Instantiating dialog_parser to populate dialog options")
    $evm.instantiate('/Service/Provisioning/StateMachines/Methods/DialogParser')
    dialog_options_hash = yaml_data(:parsed_dialog_options)
    dialog_tags_hash = yaml_data(:parsed_dialog_tags)
  end
  return dialog_options_hash, dialog_tags_hash
end

begin

  @task = $evm.root['service_template_provision_task']

  @service = @task.destination
  log_and_update_message(:info, "Service: #{@service.name} Id: #{@service.id} Tasks: #{@task.miq_request_tasks.count}")

  dialog_options_hash, dialog_tags_hash = parsed_dialog_information

  request = create_automation_request(dialog_options_hash, dialog_tags_hash)
  $evm.log(:info, "Saving automation request ID: #{request.id}")
  $evm.set_state_var(:automation_request_id, request.id)

rescue => err
  log_and_update_message(:error, "[#{err}]\n#{err.backtrace.join("\n")}")
  @task.finished("#{err}") if @task
  remove_service if @service
  exit MIQ_ABORT
end
