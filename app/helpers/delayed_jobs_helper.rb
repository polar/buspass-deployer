module DelayedJobsHelper

  puts "Loading DelayedJobsHelper"

  def uptime(delayed_job)
    now = Time.now
    if delayed_job.nil?
      return "No Job"
    end
    if delayed_job.locked_at
      tdiff = now - delayed_job.locked_at
      if tdiff < 60.seconds
        return "#{(tdiff/1.second).to_i} secs"
      elsif tdiff < 60.minutes
        return "#{(tdiff/1.minute).to_i} mins"
      else
        return "%7.2f hrs" % (tdiff/1.hour)
      end
    else
      return "Not Running"
    end
  end

  def runtime(delayed_job)
    now = Time.now
    if delayed_job.nil?
      return "No Job"
    end
    if delayed_job.run_at
      tdiff = now - delayed_job.run_at
      prefix, suffix = tdiff < 0 ? ["in", ""] : ["", "ago"]
      if tdiff.abs < 60.seconds
        return "#{prefix} #{(tdiff.abs/1.second).to_i} secs #{suffix}"
      elsif tdiff.abs < 60.minutes
        return "#{prefix} #{(tdiff.abs/1.minute).to_i} mins #{suffix}"
      else
        return "#{prefix} %7.2f hrs #{suffix}" % (tdiff.abs/1.hour)
      end
    else
      return "No Run Time"
    end
  end

end
