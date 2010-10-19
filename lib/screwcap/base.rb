module Screwcap
  class Base < OpenStruct

    # for debugging purposes only
    #def method_missing(m, *args, &block)
    #  $stdout << "For #{self.class.to_s}: calling #{m}\n"
    #  super(m, args.first)
    #end

    def set(var, *args)
      method_missing((var.to_s + "=").to_sym, args.first)
    end

    def log(msg, options = {})
      $logger ||= Logger.new(STDOUT)
      $logger.info msg
    end
  end
end
