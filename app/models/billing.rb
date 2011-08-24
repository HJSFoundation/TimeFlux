class Billing

  def initialize(customers, date, hide_empty)
    @customers = customers
    @from = date.at_beginning_of_month
    @to = date.at_end_of_month
    @hide_empty = hide_empty
  end


  def biling_report_data_2

    data = []
    
    projects = Project.for_customer(@customers)
    
    # TODO use one query to improve efficiency
    #time_entries =  TimeEntry.between(@from,@to).for_projects(projects)

    Department.all.each do |department|
      
      projects = department.projects.select { |project| @customers.include?(project.customer) }

      projects.group_by(&:customer).each do |customer,grouped_projects|

        customer_total=0
        projects_data = []

        grouped_projects.each do |project|

          time_entries =  TimeEntry.between(@from,@to).for_project(project).include_users.include_hour_types.all
          unless time_entries.empty?
            project_total = 0
            entries = []

            time_entries.group_by(&:user).each do |user,group1|
              group1.group_by(&:hour_type).each do |type,group2|

                sum = 0
                group2.each{|e| sum += e.hours}

                status_string = {}
                group2.group_by(&:status).each do |status,group3|
                  if group3.size > 0
                    status_string.merge!({status => group3.size})
                  end

                end
                billed = status_string

                entries << [user,"#{type.name}",sum, billed]
                project_total += sum
              end
            end

            projects_data << [project, project_total, entries]
            customer_total += project_total
          end
        end
        unless customer_total == 0 && @hide_empty
          data << [department.name, customer.name, customer_total, projects_data]
        end
      end

    end
    return data
  end


  def billing_report_data
    return biling_report_data_2
    


    data = []

    @customers.each do |customer|
      customer_total=0
      projects_data = []
      customer.projects.sort.each do |project|
    
    #Department.all.each do |department|
    #
    #  projects = department.projects.select { |project| @customers.include?(project.customer) }
    #  projects.sort{ |one, other| one.customer <=> other.customer }
    #  customer = projects.first.customer
    #  customer_total=0
    #  projects_data = []
    #  projects.each do |project|

        time_entries =  TimeEntry.between(@from,@to).for_project(project).include_users.include_hour_types.all
        #removed  .billed(false)
        unless time_entries.empty?
          project_total = 0
          entries = []

          time_entries.group_by(&:user).each do |user,group1|
            group1.group_by(&:hour_type).each do |type,group2|

              sum = 0
              group2.each{|e| sum += e.hours}

              status_string = {}
              
              group2.group_by(&:status).each do |status,group3|
                if group3.size > 0
                  status_string.merge!({status => group3.size})
                end

              end
              #locked = group2.select{|e|e.locked}.size
              #billed = group2.select{|e|e.billed}.size

              #billed = "#{group2.size - (locked)} / #{group2.size - (billed)} / #{billed}"

              billed = status_string

              entries << [user,"#{type.name}",sum, billed]
              project_total += sum
            end
          end

          projects_data << [project, project_total, entries]
          customer_total += project_total
        end
      end
      unless customer_total == 0 && @hide_empty
        data << [customer.name, customer_total, projects_data]
      end
    end
    data
  end
end
