require "yaml"
require "erb"
require "shell"

replace_rules = YAML.load_file "replace_rules.yml"
settings = YAML.load_file "settings.yml"

GIT_ATTRIBUTES_FILE = ".git/info/attributes_for_devenv_composer"

def abort_with_message!(reason)
  puts "Aborted because ..."
  puts reason
  exit 1
end

def validate_path!(path)
  return if File.exist? path
  abort_with_message! "No such file or directory : #{path}"
end

def set_git_attributes(app_root, rules)
  shell = Shell.new
  shell.verbose = false
  shell.transact do
    cd app_root
    system "git", "config", "core.attributesfile", GIT_ATTRIBUTES_FILE
  end

  attr_path = File.expand_path GIT_ATTRIBUTES_FILE, app_root
  File.open(attr_path, "w") do |f|
    rules.each { |file, rule| f.puts "#{file} filter=#{rule[:name]}" }
  end
end

def set_git_config(app_root, rules)
  shell = Shell.new
  shell.verbose = false
  shell.transact do
    cd app_root
    rules.each do |rule|
      option_for_sed = rule[:rules].map { |r| "-e 's/#{r[:dest]}/#{r[:org]}/g'"}.join(" ")
      system "git", "config", "filter.#{rule[:name]}.smudge", "cat"
      system "git", "config", "filter.#{rule[:name]}.clean", "sed #{option_for_sed}"
    end
  end
end

def make_docker_compose(app_name, setting)
  make_docker_config app_name, setting, "docker-compose.yml"
end

def make_docker_config(app_name, setting, filename)
  template = ERB.new(File.read(File.expand_path("#{filename}.erb", app_name)))
  yml = template.result binding

  file = File.open(File.expand_path(filename, app_name), "w")
  file.write yml
  file.close
end

replace_rules.each do |app_name, app_replace_rules|
  setting = settings[app_name]
  app_root = setting["app_root"]
  validate_path! app_root

  make_docker_compose app_name, setting

  replacing_rule_map = app_replace_rules.each_with_object({}) do |replace_rule, h|
    name = replace_rule["name"]
    dest = replace_rule["dest"]
    org = replace_rule["org"]

    replace_rule["files"].each do |file|
      h[file] ||= { name: nil, rules: [] }
      h[file][:name] = h[file][:name] ? "#{h[file][:name]},#{name}" : name
      h[file][:rules].push dest: dest, org: org
    end
  end

  set_git_config app_root, replacing_rule_map.values.uniq
  set_git_attributes app_root, replacing_rule_map
end

puts "Done!!"
