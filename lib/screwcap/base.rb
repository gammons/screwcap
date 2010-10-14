module Screwcap
  class Base < OpenStruct
    # the meat and potatoes.
    # getter / setter for any user definable option
    def method_missing(m, *args, &block)
      $stdout << "For #{self.class.to_s}: calling #{m}\n"
      super(m, args.first)
    end
  end
end
