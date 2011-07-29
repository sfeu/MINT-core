# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{MINT-core}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = [%q{Sebastian Feuerstack}]
  s.date = %q{2011-07-29}
  s.description = %q{Multimodal systems realizing a combination of speech, gesture and
graphical-driven interaction are getting part of our everyday life.

Examples are in-car assistance systems or recent game consoles.
Future interaction will be embedded into smart environments offering
the user to choose and to combine a heterogeneous set of interaction
devices and modalities based on his preferences realizing an ubiquitous
and multimodal access.

The MINT Framework enables the design, creation, and execution of
multimodal interfaces.

The MINT core gem contains all basic AUI and CUI models as well as
the basic  infrastructure to create interactors and mappings. Please
not that you need at least a CUI adapter gem to be able to actually
run a system, e.g. the MINT-rails gem.}
  s.email = [%q{Sebastian@Feuerstack.org}]
  s.executables = [%q{mint-aui}, %q{mint-cui-gfx}, %q{mint-juggernaut.sh}, %q{mint-tuplespace}]
  s.extra_rdoc_files = [%q{History.txt}, %q{Manifest.txt}, %q{PostInstall.txt}]
  s.files = [%q{Gemfile}, %q{Gemfile.lock}, %q{History.txt}, %q{MINT-core.gemspec}, %q{Manifest.txt}, %q{PostInstall.txt}, %q{README.rdoc}, %q{Rakefile}, %q{bin/mint-aui}, %q{bin/mint-cui-gfx}, %q{bin/mint-juggernaut.sh}, %q{bin/mint-tuplespace}, %q{lib/MINT-core.rb}, %q{lib/MINT-core/agent/agent.rb}, %q{lib/MINT-core/agent/aui.rb}, %q{lib/MINT-core/agent/auicontrol.rb}, %q{lib/MINT-core/agent/cui-gfx.rb}, %q{lib/MINT-core/agent/cuicontrol.rb}, %q{lib/MINT-core/mapping/complementary.rb}, %q{lib/MINT-core/mapping/mapping.rb}, %q{lib/MINT-core/mapping/on_state_change.rb}, %q{lib/MINT-core/mapping/sequential.rb}, %q{lib/MINT-core/model/aui/AIC.rb}, %q{lib/MINT-core/model/aui/AIChoice.rb}, %q{lib/MINT-core/model/aui/AIINChoose.rb}, %q{lib/MINT-core/model/aui/AIMultiChoice.rb}, %q{lib/MINT-core/model/aui/AIMultiChoiceElement.rb}, %q{lib/MINT-core/model/aui/AIO.rb}, %q{lib/MINT-core/model/aui/AIOUTDiscrete.rb}, %q{lib/MINT-core/model/aui/AISingleChoice.rb}, %q{lib/MINT-core/model/aui/AISingleChoiceElement.rb}, %q{lib/MINT-core/model/aui/AISinglePresence.rb}, %q{lib/MINT-core/model/aui/model.rb}, %q{lib/MINT-core/model/body/gesture_button.rb}, %q{lib/MINT-core/model/body/handgesture.rb}, %q{lib/MINT-core/model/body/head.rb}, %q{lib/MINT-core/model/cui/gfx/CIC.rb}, %q{lib/MINT-core/model/cui/gfx/CIO.rb}, %q{lib/MINT-core/model/cui/gfx/model.rb}, %q{lib/MINT-core/model/cui/gfx/screen.rb}, %q{lib/MINT-core/model/device/button.rb}, %q{lib/MINT-core/model/device/joypad.rb}, %q{lib/MINT-core/model/device/mouse.rb}, %q{lib/MINT-core/model/device/pointer.rb}, %q{lib/MINT-core/model/device/wheel.rb}, %q{lib/MINT-core/model/interactor.rb}, %q{lib/MINT-core/model/task.rb}, %q{lib/MINT-core/overrides/rinda.rb}, %q{script/console}, %q{script/destroy}, %q{script/generate}, %q{spec/AISinglePresence_spec.rb}, %q{spec/MINT-core_spec.rb}, %q{spec/aio_agent_spec.rb}, %q{spec/aio_spec.rb}, %q{spec/aisinglechoice_spec.rb}, %q{spec/aisinglechoiceelement_spec.rb}, %q{spec/cio_spec.rb}, %q{spec/core_spec.rb}, %q{spec/rcov.opts}, %q{spec/spec.opts}, %q{spec/spec_helper.rb}, %q{tasks/rspec.rake}, %q{.gemtest}]
  s.homepage = %q{http://github.com/sfeu/MINT-core}
  s.post_install_message = %q{PostInstall.txt}
  s.rdoc_options = [%q{--main}, %q{README.rdoc}]
  s.require_paths = [%q{lib}]
  s.rubyforge_project = %q{MINT-core}
  s.rubygems_version = %q{1.8.6}
  s.summary = %q{Multimodal systems realizing a combination of speech, gesture and graphical-driven interaction are getting part of our everyday life}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<dm-rinda-adapter>, ["~> 0.1.0"])
      s.add_runtime_dependency(%q<MINT-statemachine>, ["~> 1.2.2"])
      s.add_runtime_dependency(%q<cassowary>, ["~> 1.0.0"])
      s.add_development_dependency(%q<hoe>, ["~> 2.9"])
    else
      s.add_dependency(%q<dm-rinda-adapter>, ["~> 0.1.0"])
      s.add_dependency(%q<MINT-statemachine>, ["~> 1.2.2"])
      s.add_dependency(%q<cassowary>, ["~> 1.0.0"])
      s.add_dependency(%q<hoe>, ["~> 2.9"])
    end
  else
    s.add_dependency(%q<dm-rinda-adapter>, ["~> 0.1.0"])
    s.add_dependency(%q<MINT-statemachine>, ["~> 1.2.2"])
    s.add_dependency(%q<cassowary>, ["~> 1.0.0"])
    s.add_dependency(%q<hoe>, ["~> 2.9"])
  end
end
