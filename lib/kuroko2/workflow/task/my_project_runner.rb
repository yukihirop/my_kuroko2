module Kuroko2
  module Workflow
    module Task
      class MyProjectRunner < Execute
        def chdir
          './tmp/exam'
        end

        def shell
          # "bundle exec ./bin/rails runner -e development #{Shellwords.escape(option)}"
          "pwd"
        end
      end
    end
  end
end
