namespace :cover_me do
  
  desc "Generates and opens code coverage report."
  task :report do
    require 'cover_me'
    CoverMe.config do |conf|
      conf.at_exit = proc {
        # Do nothing, don't open any browsers (which would be the default)
      }
    end
    
    CoverMe.complete!
  end
  
end

task :test do
  Rake::Task['cover_me:report'].invoke
end

task :spec do
  Rake::Task['cover_me:report'].invoke
end