# Vamos a usar clase porque los PartialBlock son instanciables -> No mixins

class PartialBlock
  attr_accessor :tipos, :bloque
  def initialize(tipos, &block)
    if(tipos.length != block.arity)
      raise "El bloque deberia tener la misma aridad que la lista de tipos"
    end

    self.tipos = tipos
    self.bloque = block
  end

  def matches?(*args)
    # el zip lo que hace es -> [1,2,3].zip(["a","b","c"]) -->> [(1,"a"), (2,"b"), (3,"c")]
    el_tipo_de_los_parametros_pasados_coincide_con_el_esperado = tipos.zip(args).all? do |tipo_y_parametro|
      tipo, parametro = tipo_y_parametro
      parametro.is_a? tipo # considera tanmbien el tipo del supertipo ej: String.is_a? Object ->> true
    end
    args.length == tipos.length && el_tipo_de_los_parametros_pasados_coincide_con_el_esperado
  end
end