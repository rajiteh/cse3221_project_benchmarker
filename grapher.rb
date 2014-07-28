#!/usr/bin/env ruby -wKU
require 'open3'
require 'gruff'
require 'logger'

class SchedulerBenchmarker

	def log
		unless @log
			@log = Logger.new(STDOUT)
			@log.level = Logger::INFO
		end
		@log
	end
	def initialize(opts={})
		options = {
			:fcfs => {
				:disabled => false,
				:binary => './bin/fcfs',
				:arguments => '-f ./bin/CPULoad.dat -c %d',
				:graph_title => 'FCFS Scheduler',
				:graph_file_prefix => 'fcfs'
				},
			:rr => {
				:disabled => false,
				:quantum_from => 30,
				:binary => './bin/rr',
				:arguments => '-f ./bin/CPULoad.dat -c %d 22',
				:graph_title => 'Round Robin Scheduler',
				:graph_file_prefix => 'rr'
			},
			:fbq => {
				:disabled => false,
				:quantum_from => 50,
				:binary => './bin/fbq',
				:arguments => '-f ./bin/CPULoad.dat %d %d',
				:graph_title => 'FBQ Scheduler',
				:graph_file_prefix => 'fbq'
			}
		}.merge(opts)

		
		unless options[:fcfs][:disabled] 
			log.info("Benchmarking FCFS")
			fcfs_out = run_benchmark(
				options[:fcfs][:binary],
				options[:fcfs][:arguments], 
				[[1],[2],[3],[4],[5],[6],[7],[8],[9],[10]]
			)
			log.info("Generating graphs for FCFS")
			make_graph(options[:fcfs][:graph_title],
				options[:fcfs][:graph_file_prefix],
				fcfs_out,
				'CPU Count')
		end
		unless options[:rr][:disabled] 
			log.info("Benchmarking Round Robin")
			rr_out = run_benchmark(
				options[:rr][:binary],
				options[:rr][:arguments], 
				generate_rr_quantums(options[:rr][:quantum_from])
			)
			log.info("Generating graphs for Round Robin")
			make_graph(options[:rr][:graph_title],
				options[:rr][:graph_file_prefix],
				rr_out,
				'Quantum')
		end

		unless options[:fbq][:disabled] 
			log.info("Benchmarking FBQ")
			fbq_out = run_benchmark(
				options[:fbq][:binary],
				options[:fbq][:arguments], 
				generate_fbq_quantums(options[:fbq][:quantum_from])
			)
			log.info("Generating graphs for FBQ")
			make_graph(options[:fbq][:graph_title],
				options[:fbq][:graph_file_prefix],
				fbq_out,
				'Quantum')
		end
		log.info("All done")
		0
	end

	def run_benchmark(filename,arguments,test_value_arrays)
		ret = []
		test_value_arrays.each_with_index do |val, ind|
			processed_arg = sprintf(arguments,*val)
			log.info("Running test with #{filename} #{processed_arg} #{ind}/#{test_value_arrays.count}")
			Open3.popen3("#{filename} #{processed_arg}") do |i, o, e, t|
				output = o.read.to_s
				ret.push({
					:arguments => val,
					:turnaround_time => /Avg turn-around time\t:\t([0-9\.]*)\n/.match(output)[1],
					:wait => /Avg waiting time\t:\t([0-9\.]*)\n/.match(output)[1],
					:cpu_utilization => /Avg CPU Utilization\t:\t([0-9\.]*)%\n/.match(output)[1],
					:end_time => /Time at last process\t:\t([0-9]*)\n/.match(output)[1],
					})
			end
		end
		ret
	end


	def make_graph(title, file_prefix, data, xlabel)
		labels = {}
		wait_times = []
		data.map { |h| h[:arguments] }.each_with_index do |d,i| 
			labels[i] = d.join('-')
		end
		gruff(title,
			labels,:wait_time,
			data.map { |h| h[:wait].to_f },
			"#{file_prefix}_wait_time.png",xlabel)

		gruff(title,
			labels,:turnaround_time,
			data.map { |h| h[:turnaround_time].to_f },
			"#{file_prefix}_turnaround.png",xlabel)
		
		gruff(title,
			labels,:cpu_utilization,
			data.map { |h| h[:cpu_utilization].to_f },
			"#{file_prefix}_cpu.png",xlabel)

		gruff(title,
			labels,:end_time,
			data.map { |h| h[:end_time].to_f },
			"#{file_prefix}_time.png",xlabel)	
	end


	def gruff(title,labels,data, datas, name, xlabel='',fontsize=10)
		log.info("Making graph #{data} of #{title}")
		g = Gruff::Line.new(800)
		g.margins = 10
		g.x_axis_label = xlabel
		g.marker_font_size = fontsize
		g.title = title
		g.labels = labels
		g.data(data, datas)
		g.write("./out/#{name}")
	end

	def generate_fbq_quantums(p)
		ret = []
		p.times { |i| (i - 1).times { |j| ret.push [i - 1 - j, i ] } unless i == 0}
		ret
	end

	def generate_rr_quantums(p)
		ret = []
		p.times { |i| ret.push [i] unless i == 0 }
		ret
	end
end

SchedulerBenchmarker.new
=begin
#Configration options
SchedulerBenchmarker.new({
			:fcfs => {
				:disabled => false,
				:binary => './bin/fcfs',
				:arguments => '-f ./bin/CPULoad.dat -c %d',
				:graph_title => 'FCFS Scheduler',
				:graph_file_prefix => 'fcfs'
				},
			:rr => {
				:disabled => false,
				:quantum_from => 30,
				:binary => './bin/rr',
				:arguments => '-f ./bin/CPULoad.dat -c %d 22',
				:graph_title => 'Round Robin Scheduler',
				:graph_file_prefix => 'rr'
			},
			:fbq => {
				:disabled => false,
				:quantum_from => 50,
				:binary => './bin/fbq',
				:arguments => '-f ./bin/CPULoad.dat %d %d',
				:graph_title => 'FBQ Scheduler',
				:graph_file_prefix => 'fbq'
			})
=end