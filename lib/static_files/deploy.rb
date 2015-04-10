load 'config/deployment_config'
set :use_sudo, false
set :ssh_options, { :forward_agent => true }

# http://stackoverflow.com/questions/1524204/using-capistrano-to-deploy-from-different-git-branches
# http://stackoverflow.com/questions/21590077/how-to-pass-arguments-to-capistrano-3-tasks-in-deploy-rb
#call with... bundle exec cap <env> deploy:cold[<branchname>]
set :branch, "master" # DEFAULT TO MASTER
#set :env, fetch(:env, "development")

# LAUNCHPAD -- a lot of this should go in application.rb
set :NGINX_CONF_NAME, "#{fetch(:APP_NAME)}_nginx_conf"
set :APPS_HOME, "/apps"
set :APP_ROOT, "#{fetch(:APPS_HOME)}/#{fetch(:APP_NAME)}"
set :NGINX_HOME, "/usr/local/openresty/nginx"
set :CONFIG_DIR, Dir.pwd


namespace :erb do

  task :generate_nginx_conf do
    on roles(:web) do
      p "generating nginx configuration file"
      template = File.read(File.join(File.dirname(__FILE__), "templates/app_nginx_conf.erb"))
      app_name = "#{fetch(:APP_NAME)}"
      http_port = "#{fetch(:HTTP_PORT)}"
      ssl_port = "#{fetch(:SSL_PORT)}"
      result = ERB.new(template).result(binding)
      #p result
      temp_filename = "config/temp_nginx_conf"
      File.open(temp_filename, 'w') { |file| file.write(result) }
      upload! temp_filename, "#{fetch(:APP_ROOT)}/config/#{fetch(:APP_NAME)}_nginx_conf"
      File.delete(temp_filename)
    end
  end

  task :generate_unicorn_conf do
    on roles(:web) do
      p "generating unicorn configuration file"
      template = File.read(File.join(File.dirname(__FILE__), "templates/unicorn.rb.erb"))
      unicorn_worker_count = "#{fetch(:UNICORN_WORKER_COUNT)}"
      unicorn_port = "#{fetch(:UNICORN_PORT)}"
      app_root = "#{fetch(:APP_ROOT)}"
      app_name = "#{fetch(:APP_NAME)}"
      result = ERB.new(template).result(binding)
      #p result
      File.open('config/unicorn.rb', 'w') { |file| file.write(result) }
      upload! "config/unicorn.rb", "#{fetch(:APP_ROOT)}/config/unicorn.rb"
      File.delete('config/unicorn.rb')
    end
  end

end

task :hello do
  puts "hello world"
  puts "x", Dir.pwd, "x"
  puts Dir.pwd
  on roles(:web) do
      execute "echo 'test1'"
      execute "echo #{fetch(:msg, "N/A")}"
  end
end

task :echo_test do
  puts "printing a message to /tmp/cap_echo_test.txt"
  on roles(:web) do
      execute "echo 'hi' > /tmp/cap_echo_test.txt"
  end
end

namespace :bundle do

  desc "run bundle install and ensure all gem requirements are met"
  task :install do
    on roles(:web) do
      execute "cd #{fetch(:APP_ROOT)}/ && bundle install"
    end
  end

end

namespace :database do

   task :migrate do
     on roles(:web) do
       execute "cd #{fetch(:APP_ROOT)}/ && rake db:migrate"
     end
   end

   task :drop do
     on roles(:web) do
       execute "cd #{fetch(:APP_ROOT)}/ && rake db:drop"
     end
   end

   task :seed do
     on roles(:web) do
       execute "cd #{fetch(:APP_ROOT)}/ && rake db:seed"
     end
   end

end


namespace :deploy do

  desc "update"
  task :update do
    invoke 'deploy:stop_servers'
    invoke 'deploy:clean'
    invoke 'deploy:fetch_app'
    invoke 'deploy:configure'
  end

  desc "restart"
  task :restart do
  end

  desc "fetch app and configure (move ssl certs, link server configs, etc. then stop/start servers"
  task :cold, :branch_param do |task, args|

    puts "brr... cold deploy time"
    #puts "xxxxxx"
    #puts args[:branch_param]
    set :branch, args[:branch_param]
    #puts "xxxxxx"

    invoke 'deploy:stop_servers'
    invoke 'deploy:clean'

    # http://stackoverflow.com/questions/21590077/how-to-pass-arguments-to-capistrano-3-tasks-in-deploy-rb
    # a way to invoke the task and pass along the arguments
    #Rake::Task["deploy:fetch_app"].invoke(args[:branch_param])
    invoke 'deploy:fetch_app'

    invoke 'deploy:configure'
    invoke 'database:migrate'
  end

  desc "move ssl certs, link server configs, stop/start servers"
  task :configure do
    invoke 'deploy:ssl_certs'
    invoke 'erb:generate_nginx_conf'
    invoke 'erb:generate_unicorn_conf'
    invoke 'deploy:nginx_conf'
    invoke 'bundle:install'
    invoke 'deploy:reload'
  end

  desc "does a git pull and restarts servers"
  task :reload do
    invoke 'deploy:pull_app'
    invoke 'deploy:stop_servers'
    invoke 'deploy:start_servers'
  end

  desc "updates the app to latest master"
  task :pull_app do
    on roles(:web) do
        execute "cd #{fetch(:APP_ROOT)} && git pull"
    end
  end

  desc "fetch app from github"
  #task :fetch_app, :branch_param do |task, args|
  task :fetch_app do
    on roles(:web) do
        # works
        #set :branch, args[:branch_param]
     	execute "cd #{fetch(:APPS_HOME)} && git clone #{fetch(:GITHUB_SSH)} #{fetch(:APP_ROOT)} && cd #{fetch(:APP_ROOT)} && git checkout #{fetch(:branch)}"
    end
  end

  desc "copy ssl certs (the self-signed ones that come with this app) to nginx config"
  task :ssl_certs do
    on roles(:web) do
        execute "cp #{fetch(:APP_ROOT)}/config/ssl/* #{fetch(:NGINX_HOME)}/ssl"
    end
  end

   desc "set up nginx conf files"
   task :nginx_conf do
     on roles(:web) do
       puts Dir.pwd
       begin
#          begin
#             execute "mv #{fetch(:NGINX_HOME)}/conf/nginx.conf #{fetch(:NGINX_HOME)}/conf/nginx.conf.last"
#          rescue Exception => error
#              puts "can't rename nginx.conf.  it probably didn't exist"
#          end
#          begin
#              execute "unlink #{fetch(:NGINX_HOME)}/conf/nginx.conf"
#          rescue Exception => error
#              puts "error unlinking nginx.conf.  it probably didn't exist"
#          end
#          execute "cp #{fetch(:APP_ROOT)}/config/nginx.conf #{fetch(:NGINX_HOME)}/conf/nginx.conf"

          execute "cp #{fetch(:APP_ROOT)}/config/#{fetch(:NGINX_CONF_NAME)} #{fetch(:NGINX_HOME)}/conf/sites-available"
          begin
              execute "unlink #{fetch(:NGINX_HOME)}/conf/sites-enabled/#{fetch(:NGINX_CONF_NAME)}"
          rescue Exception => error
              puts "error unlinking app nginx server config.  it probably didn't exist"
          end
          execute "ln -s #{fetch(:NGINX_HOME)}/conf/sites-available/#{fetch(:NGINX_CONF_NAME)} #{fetch(:NGINX_HOME)}/conf/sites-enabled"
       rescue Exception => error
         puts "Could not move existing nginx.conf"
       end
     end
   end

   desc "cleans out the deploy directory"
   task :clean do
    on roles(:web) do
      begin
        execute "rm -r #{fetch(:APP_ROOT)}"
      rescue Exception => error
        puts "could not delete app.  maybe it doesn't exist yet."
      end
    end
  end

  desc "restarts unicorn and nginx"
  task :restart do
    invoke 'deploy:stop_servers'
    invoke 'deploy:start_servers'
  end


  desc "stop unicorn"
  task :stop_unicorn do
    on roles(:web) do
      begin
        puts "stopping unicorn"
        execute "kill -9 $(cat #{fetch(:APP_ROOT)}/tmp/pid/unicorn.pid)"
      rescue Exception => error
        puts "error stopping unicorn... maybe the servers were not on?"
      end
    end
  end

  desc "stop nginx"
  task :stop_nginx do
    on roles(:web) do
      begin
        puts "stopping nginx (openresty)"
        execute :sudo, "#{fetch(:NGINX_HOME)}/sbin/nginx -s stop"
      rescue Exception => error
        puts "error stopping nginx... maybe the servers were not on?"
      end
    end
  end

  task :stop_servers do
    invoke 'deploy:stop_unicorn'
    invoke 'deploy:stop_nginx'
  end

  task :start_servers do
    invoke 'deploy:start_unicorn'
    invoke 'deploy:start_nginx'
  end

  task :start_unicorn do
    on roles(:web) do
      puts "starting unicorn"
      execute "cd #{fetch(:APP_ROOT)}/ && bundle exec unicorn -c #{fetch(:APP_ROOT)}/config/unicorn.rb -D"
    end
  end

  task :start_nginx do
    on roles(:web) do
      puts "starting nginx"
      execute :sudo, "#{fetch(:NGINX_HOME)}/sbin/nginx"
    end
  end
end
