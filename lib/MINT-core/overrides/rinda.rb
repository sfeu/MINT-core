require "rinda/tuplespace"

module Rinda
  class TupleSpace
    def take_all(tuple)
      read_all(tuple).each { |t|
        take(t)
      }
    end
    

  end
  
  # fixed Templates to  support partially matching
  class Template
    def match(tuple)
      return false unless tuple.respond_to?(:size)
      return false unless tuple.respond_to?(:fetch)
      return false unless self.size <= tuple.size
      each do |k, v|
        begin
          it = tuple.fetch(k)
        rescue
          return false
        end
        next if v.nil?
        next if v == it
        next if v === it
        return false
      end
      return true
    end
  end
end
