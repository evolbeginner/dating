def get_rtc(file, root_two_children_names)
  rtc_info = Hash.new
  in_fh = File.open(file, 'r')
  in_fh.each_line do |line|
    line.chomp!
    next if line =~ /^#|^$/
    line_arr = line.split("\t")

    symbiont = line_arr[0].gsub('_', '_').split(',')
    rtc = Symbiont.new(symbiont)

    (1..line_arr.size-1).each do |index|
      ele = line_arr[index]
      host = ele.split(':')[0].gsub('_', '_').split(',')
      prob = ele.split(':')[1]

      host_obj = Host.new(host)
      host_obj.prob = prob
      rtc.hosts << host_obj
    end

    root_obj = Host.new(root_two_children_names)

    curr_total_prob = rtc.hosts.map{|host|host.prob}.reduce(&:+)
    if curr_total_prob < 1
      root_obj.prob = 1 - curr_total_prob
      rtc.hosts << root_obj
    end

    if not rtc_info.include?(symbiont)
      rtc_info[symbiont] = Array.new
    end
    rtc_info[symbiont] << rtc
  end
  in_fh.close
  return(rtc_info)
end
