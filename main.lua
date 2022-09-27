PROJECT = 'test'
VERSION = '2.0.0'
require 'log'
LOG_LEVEL = log.LOGLEVEL_TRACE
require 'sys'


require 'eink'

sys.taskInit(function()
	while true do
		-- log.info('test',array)
		log.info('Hello world!')
		sys.wait(5000)
	end
end)

sys.init(0, 0)
sys.run()