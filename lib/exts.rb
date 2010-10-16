class Array
  def blank?
    self.nil? || self.size == 0
  end
end

class NilClass
  def blank?
    true
  end
end
