module Screwcap
  class Base < OpenStruct
    def set(var, *args)
      method_missing((var.to_s + "=").to_sym, args.first)
    end
  end
end
