require 'rspec'
require_relative '../lib/multimethods'

describe "Partial Blocks" do

  describe "construccion de partial block" do
    it("deberia poder crearse con una lista de longitud acorde al bloque") do
      expect { PartialBlock.new([String]) do |s| "Mucho no importa" end}.not_to raise_error
    end

    it("No deberia poder crearse con una lista de longitud menor a la aridad del bloque") do
      expect{PartialBlock.new([String]) do |s1, s2| "Mucho no importa" end}
        .to raise_error("El bloque deberia tener la misma aridad que la lista de tipos")
    end

    it("No deberia poder crearse con una lista de longitud mayor a la aridad del bloque") do
      expect{PartialBlock.new([String, String]) do |s1| "Mucho no importa" end}
        .to raise_error("El bloque deberia tener la misma aridad que la lista de tipos")
    end
  end

  describe "matches" do
    it("Deberia matchear el mismo tipo") do
      un_bloque = PartialBlock.new([String]) do |s|
        "Mucho no importa"
      end
      expect(un_bloque.matches?("unString")).to be(true)
    end

    it("Deberia matchear super tipo") do
      un_bloque = PartialBlock.new([Object]) do |s|
        "Mucho no importa"
      end
      expect(un_bloque.matches?("un_string")).to be(true)
    end

    it("Deberia aceptar modulos como tipos para la firma") do
      un_modulo = Module.new
      una_clase = Class.new
      una_clase.include(un_modulo)

      un_bloque = PartialBlock.new([un_modulo]) do |s|
        "Mucho no importa"
      end
      expect(un_bloque.matches?(una_clase.new)).to be(true)
    end

    it("Deberia no matchear si no ha relacion") do
      un_bloque = PartialBlock.new([String]) do |s|
        "Mucho no importa"
      end
      expect(un_bloque.matches?(3)).to be(false)
    end

    it("Deberia no matchear si no coincide la cantidad de argumentos") do
      un_bloque = PartialBlock.new([String]) do |s|
        "Mucho no importa"
      end

      expect(un_bloque.matches?("hola", "mundo")).to be(false)
    end

    it("Deberia matchear con multiples parametros") do
      un_bloque = PartialBlock.new([String, String]) do |s1,s2|
        "Mucho no importa"
      end
      expect(un_bloque.matches?("s1", "s2")).to be(true)
      expect(un_bloque.matches?("s1", 1)).to be(false)
      expect(un_bloque.matches?(1, 3)).to be(false)
    end
  end

  describe "call" do
    helloBlock = PartialBlock.new([String]) do |who|
      "Hello #{who}"
    end

    it("Deberia ejecutar con el parametro que le paso") do
      expect(helloBlock.call("Pepe")).to eq("Hello Pepe")
    end

    it("Deberia arrojar error cuando le paso un tipo que no corresponde") do
      expect{helloBlock.call(1)}.to raise_error("El bloque no coincide con los argumentos")
    end

    it("Deberia ejecutar con el parametro que le paso") do
      new_block = PartialBlock.new([Object, Object]) do |left, right|
        [left, right]
      end
      expect(new_block.call(1, "hola")).to eq([1,"hola"])
    end
  end
end

describe 'Multimethods' do
  class A
    partial_def :concat, [String, String] do |s1, s2|
      s1 + s2
    end

    partial_def :concat, [String, Integer]  do |s1, n|
      s1 * n
    end

    #partial_def :concat, [Array] do |a|
    #  a.join
    #end

    partial_def :concat, [Object, Object] do |o1, o2|
      'Objetos Concatenados'
    end

    partial_def :concat, [String] do |s1|
      my_name + s1
    end

    def my_name
      'A'
    end
  end

  module B
    partial_def :concat, [Object, Object] do |s1,s2|
      "Objetos concatenados"
    end
    partial_def :concat, [String, Integer] do |s1,n|
      s1 * n
    end
  end

  it 'si existe algun partial block que matchee para los parametros se usa ese partial block' do
    expect(A.new.concat('hello', ' world')).to eq('hello world')
    expect(A.new.concat('hello', 3)).to eq('hellohellohello')
  end

  it 'si no existe ningún partial block que matchee dados los parametros explota con no method error' do
    expect { A.new.concat(['hello', ' world', '!']) }.to raise_error(NoMethodError, "Ninguna definicion aplica para los argumentos")
  end

  it("Se puede usar un multimethod definido en un modulo") do
    una_clase = Class.new
    una_clase.include(B)

    expect(una_clase.new.concat(1,2)).to eq("Objetos concatenados")
  end

  it("se puede obtener un multimethod definido") do
    multimethod = A.multimethod(:concat)
    expect(multimethod).not_to eq(nil)
  end

  it("Se pueden conocer que multimethods define una clase") do
    expect(A.multimethods()).to eq([:concat])
  end

  it("se pueden conocer que multimethods define un modulo") do
    expect(A.multimethods()).to eq([:concat])
  end

  it 'un objeto con multimethod deberia saber responder al metodo asociado a ese multimethod' do
    expect(A.new.respond_to?(:concat)).to eq true
  end

  it 'un objeto con multimethod deberia saber responder al metodo asociado a ese multimethod dados ciertos tipos' do
    expect(A.new.respond_to?(:concat, false, [String, String])).to eq true
  end

  it 'un objeto con multimethod no deberia saber responder al metodo asociado a ese multimethod dados ciertos tipos que no coinciden a los de su multimethod' do
    expect(A.new.respond_to?(:concat, false, [String, BasicObject])).to eq false
  end

  it 'deberia ejecutarse en el contexto del objeto' do
    expect(A.new.concat('sd')).to eq 'Asd'
  end

  it 'deberia permitir agregar multimethods una vez que la clase ya fue creada' do
    class C
      partial_def :+, [String] do |n| n + 'B' end
    end

    class C
      partial_def :+, [Float] do |n| 42 end
    end

    expect(C.new + 'asd').to eq 'asdB'
    expect(C.new + 3.2).to eq 42
  end

=begin
  context 'multimethods con tipado estructural' do
    class Pepita
      attr_accessor :energia

      def initialize
        @energia = 0
      end

      partial_def :interactuar_con, [[:ser_comida_por]] do |comida|
        comida.ser_comida_por(self)
      end

      partial_def :interactuar_con, [[:entrenar, :alimentar]] do |entrenador|
        entrenador.entrenar(entrenador.alimentar(self))
      end
    end

    class Comida; def ser_comida_por(comensal); comensal.energia += 30; comensal; end ; end

    class Entrenador
      def alimentar(golondrina); golondrina.interactuar_con(Comida.new); golondrina end
      def entrenar(golondrina); golondrina.energia -= 10; golondrina end
    end
  end

  it 'un objeto deberia poder responder que sabe contestar metodos con tipado estructural' do
    expect(Pepita.new.respond_to?(:interactuar_con, false, [Comida])).to eq true
    expect(Pepita.new.respond_to?(:interactuar_con, false, [Entrenador])).to eq true
    expect(Pepita.new.respond_to?(:interactuar_con, false, [Fixnum])).to eq false
  end

  it 'un objeto deberia contestar con el multimethod correspondiente' do
    expect(Pepita.new.interactuar_con(Comida.new).energia).to eq 30
    expect(Pepita.new.interactuar_con(Entrenador.new).energia).to eq 20
  end
=end

end

describe("Pruebita de contexto") do

  class Tanque

    def ataca_con_camion(objetivo)
      "Atacar con camion"
    end

    def ataca_con_ametralladora(objetivo)
      "Atacar con ametralladora"
    end

    partial_def :ataca_a, [Tanque] do |objetivo|
      self.ataca_con_camion(objetivo)
    end

    partial_def :ataca_a, [Soldado] do |objetivo|
      self.ataca_con_ametralladora(objetivo)
    end
  end

  class Avion
    #... implementación de avión
  end

  class Soldado
    #... implementación de avión
  end

  it("deberia funcionar con self") do
    tanque = Tanque.new
    soldado = Soldado.new

    expect(tanque.ataca_a(soldado)).to eq("Atacar con ametralladora")
  end

end