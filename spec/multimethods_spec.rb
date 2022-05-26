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
      expect(helloBlock.call(1))
        .to raise_error("El bloque no coincide con los argumentos")
    end
  end
end