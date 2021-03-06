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

  def matches_types?(actual_types)
    # el zip lo que hace es -> [1,2,3].zip(["a","b","c"]) -->> [(1,"a"), (2,"b"), (3,"c")]
    el_tipo_de_los_parametros_pasados_coincide_con_el_esperado = tipos.zip(actual_types).all? do |tipo_original_y_actual|
      tipo, tipo_actual = tipo_original_y_actual
      tipo_actual.ancestors.include? tipo # considera tanmbien el tipo del supertipo ej: String.is_a? Object ->> true
    end
    actual_types.length == tipos.length && el_tipo_de_los_parametros_pasados_coincide_con_el_esperado
  end

  # *args ->> (1,2,3) ... PARAMETROS SEPARADOS POR COMA
  # args  ->> [1,2,3] ... ARRAY
  def call(*args)
    validate_args(*args)

    bloque.call(*args)
  end

  def validate_args(*args)
    raise "El bloque no coincide con los argumentos" unless matches?(*args)
  end


  def call_with_context(contexto, *args)
    validate_args(*args)
    contexto.instance_exec(*args, &bloque)
  end

  def distance_to(*args)
    (1 .. args.size).zip(args.zip(tipos))
                    .sum {|index, argAndType|
                      arg, type = argAndType
                      param_distance(arg ,type) * index
                    }
  end

  private
  def param_distance(parameter, type)
    parameter.class.ancestors.index(type)
  end
end

class Module
  def partial_def(selector, tipos, &bloque)
    # guardar la info de esta definicion parcial
    # asegurar que entiendan ese selector y reaccionen como corresponde

    multimethod = self.devolver_multimethod(selector)
    # devolver_multimethod es lo mismo que: self.has_multimethod(selector) ? multimethod(selector) : self.define_multimethod(selector)

    multimethod.add_definition(tipos, &bloque)
    # con esto las instancias de la clase que implemente partial_def van a poder ejecutar el msj definido
    # en el ej. del test una instancia de la clase A entiende concat: A.new.concat("hola", 3) -> "holaholahola"
    define_method(selector) do |*args| # *args van a ser los parametros que pueda recibir el method definido en partial_def
                                        # ej. en: A.new.concat("hola",3) -> *args me va a traer a ("hola", 3)

                                        #puts self ==> este self es una instancia de la clase, NO la clase en donde se definen los partial_def 's
      multimethod.call(self, *args) # el multimethod tiene que saber cual de todos los partial_def tiene que ejecutar, tiene muchas definiciones para un mismo selector
    end
  end

  def define_multimethod(selector)
    nuevo_multimethod = Multimethod.new(selector)
    self.all_multimethods << nuevo_multimethod
    nuevo_multimethod
  end

  def all_multimethods
    @all_multimethods ||= [] # si no existia que la cree vacia
    @all_multimethods
  end

  def has_multimethod?(selector)
    self.all_multimethods.any? do|multimethod|
      multimethod.selector == selector
    end
  end

  def devolver_multimethod(selector)
    if(has_multimethod?(selector))
      multimethod(selector)         # devuelve el que ya tenia guardado en la lista all_multimethods
    else
      define_multimethod(selector)  # crea uno y lo devuelve
    end
  end

  def multimethod(selector)
    self.all_multimethods.find do|multimethod|
      multimethod.selector == selector
    end
  end

  def multimethods
    self.all_multimethods.collect { |multimethod| multimethod.selector}
  end
end

# creando esta clase cada Multimethod va a tener que recordar cada una de las posibles firmas
# que va a tener para ese selector
class Multimethod
  attr_accessor :selector, :definiciones

  def initialize(selector)
    self.selector = selector
    self.definiciones = []
  end

  def add_definition(tipos, &bloque)
    definiciones << PartialBlock.new(tipos,&bloque)
  end

  def call(contexto, *args)
    # buscar la definicion
    partialBlock = definiciones
                     .select {|definicion| definicion.matches?(*args) }
                     .min_by {|definicion| definicion.distance_to(*args)}

    if (partialBlock.nil?)
      raise NoMethodError, "Ninguna definicion aplica para los argumentos"
    end
    # ejecutarla
    partialBlock.call_with_context(contexto, *args)
  end

  def is_defined(tipos)
    definiciones.any? {|definicion| definicion.matches_types?(tipos)}
  end
end

class Object
  alias_method :___respond_to?, :respond_to? # me guardo el respond_to? original para poder usarlo xq al redefinir el respond_to? lo estamos pisando

  def respond_to?(selector, bool = false, tipos = nil)
    if tipos.nil?
      self.___respond_to?(selector, bool) # mantenemos el comportamiento original
    else
      self.class.has_multimethod?(selector) && self.class.multimethod(selector).is_defined(tipos)
    end
  end
end