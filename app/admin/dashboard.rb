ActiveAdmin.register_page "Dashboard" do

  menu :priority => 1, :label => proc{ I18n.t("active_admin.dashboard") }

  content :title => proc{ I18n.t("active_admin.dashboard") } do

    panel "Stats" do
      div do
        "#{User.count} Nutzer/innen"
      end
      div do
        "#{Keyword.joins(:meta_datum => :media_resource).where(:media_resources => {:type => ["MediaEntry", "MediaSet", "FilterSet"]}).count} Schlagworte"
      end
      div do
        "#{MediaEntry.count} Medien"
      end
      div do
        "#{MediaSet.count} MediaSets"
      end

    end

    panel "Deployment Info" do

      table do
        tbody do 
          tr do
            td do
              "Most recent commit:"
            end
            td do
              div do
                begin
                  span do
                    link_to ("https://github.com/zhdk/madek/commit/" + `git log --pretty='%H'  -1`) do 
                      `git log --pretty=format':%h' -1` + ' @GITHUB'
                    end 
                  end
                  span do
                    `git log --pretty=format':%cn %d %s' --decorate -1`
                  end
                rescue
                  'not available'
                end
              end
            end
          end
          tr do
            td do
              'Rails root created at:'
            end
            td do
              Rails.root.ctime
            end
          end
        end
      end

    end

  

  columns do

      column do
        panel "NewRelic Monitor" do

          div do
            br
            text_node %{<iframe src="https://rpm.newrelic.com/public/charts/gIytbTM3fOX" width="45%" height="300" scrolling="no" frameborder="no"></iframe>}.html_safe
            text_node %{<iframe src="https://rpm.newrelic.com/public/charts/l7XFHy0fuKm" width='45%' height="300" scrolling="no" frameborder="no"></iframe>}.html_safe

          end

          div do
            br
            text_node %{<iframe src="https://rpm.newrelic.com/public/charts/xn28T6rQcP" width="45%" height="300" scrolling="no" frameborder="no"></iframe>}.html_safe
            text_node %{<iframe src="https://rpm.newrelic.com/public/charts/kUeO5CwzBC1" width="45%" height="300" scrolling="no" frameborder="no"></iframe>}.html_safe

          end
        end
      end

    end # columns

 end # content



end
