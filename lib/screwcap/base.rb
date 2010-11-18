module Screwcap
  class Base < OpenStruct
    def set(var, *args)
      method_missing((var.to_s + "=").to_sym, args.first)
    end

    def clone_from(object)
      object.table.each {|k,v| self.set(k,v) unless k.to_s[0..1] == "__" }
    end
  end
end
