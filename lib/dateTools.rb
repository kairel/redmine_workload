# -*- encoding : utf-8 -*-
class DateTools

  # Returns a list of all regular working weekdays.
  # 1 is monday, 7 is sunday (same as in Date::cwday)
  def self.getWorkingDays()
    result = Set::new

    result.add(1) if Setting['plugin_redmine_workload']['general_workday_monday'] != ''
    result.add(2) if Setting['plugin_redmine_workload']['general_workday_tuesday'] != ''
    result.add(3) if Setting['plugin_redmine_workload']['general_workday_wednesday'] != ''
    result.add(4) if Setting['plugin_redmine_workload']['general_workday_thursday'] != ''
    result.add(5) if Setting['plugin_redmine_workload']['general_workday_friday'] != ''
    result.add(6) if Setting['plugin_redmine_workload']['general_workday_saturday'] != ''
    result.add(7) if Setting['plugin_redmine_workload']['general_workday_sunday'] != ''

    return result
  end

  @@getHolydayDaysInTimespanCache = {}

  def self.getHolydaysDaysInTimespan(timeSpan, user, noCache = true)
    raise ArgumentError unless timeSpan.kind_of?(Range)
    raise ArgumentError unless user.kind_of?(User)

    return @@getHolydayDaysInTimespanCache[timeSpan][user] unless @@getHolydayDaysInTimespanCache[timeSpan].nil? ||
        @@getHolydayDaysInTimespanCache[timeSpan][user].nil? || noCache

    issue = Issue.arel_table
    project = Project.arel_table
    issue_status = IssueStatus.arel_table

    # Fetch all issues that on holidays project
    issues = Issue.joins(:project).
        joins(:status).
        joins(:assigned_to).
        where(issue[:assigned_to_id].eq(user.id)).# Are assigned to the interesting user
        where(project[:name].eq("CONGES")). # Are on the interesting project
        where(issue_status[:is_closed].eq(false)) # Is valid

    result = Set::new
    timeSpan.each do |day|
      issues.each do |issue|
        if (day >= issue.start_date && day <= issue.due_date)
          result.add(day)
        end
      end
    end

    @@getHolydayDaysInTimespanCache[timeSpan] = {} if @@getHolydayDaysInTimespanCache[timeSpan].nil?
    @@getHolydayDaysInTimespanCache[timeSpan][user] = result

    return result

  end

  @@getWorkingDaysInTimespanCache = Hash::new

  def self.getWorkingDaysInTimespan(timeSpan, noCache = true)
    raise ArgumentError unless timeSpan.kind_of?(Range)

    return @@getWorkingDaysInTimespanCache[timeSpan] unless @@getWorkingDaysInTimespanCache[timeSpan].nil? || noCache

    workingDays = self::getWorkingDays()

    result = Set::new

    timeSpan.each do |day|
      if workingDays.include?(day.cwday) then
        result.add(day)
      end
    end

    @@getWorkingDaysInTimespanCache[timeSpan] = result

    return result
  end

  def self.getRealDistanceInDays(timeSpan)
    raise ArgumentError unless timeSpan.kind_of?(Range)

    return self::getWorkingDaysInTimespan(timeSpan).size
  end
end
