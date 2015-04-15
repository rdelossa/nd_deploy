require "nd_deploy/version"
require "nd_deploy/engine"

# error classes
#require "nd_deploy/api_authorization_error"

require 'rails/generators'
require 'fileutils'

module NDDeploy

end

class NdDeployInitializerGenerator < Rails::Generators::Base
    
    desc "This generator creates an webservices initializer file at config/initializers"
    
    def create_initializer_file
        
        static_files_path = File.expand_path(File.dirname(__FILE__)) + '/static_files' #the '__FILE__' consists of two underscores
        
        app_path = Dir.pwd+'/config'
        
        FileUtils.copy_entry(static_files_path, app_path)
        
    end

end

class NdDeployGenerator < Rails::Generators::NamedBase
    



end
