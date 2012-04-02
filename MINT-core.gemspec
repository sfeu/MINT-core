# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{MINT-core}
  s.version = "1.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = [%q{Sebastian Feuerstack}]
  s.date = %q{2011-11-11}
  s.description = %q{Multimodal systems realizing a combination of speech, gesture and graphical-driven interaction are getting part of our everyday life.

Examples are in-car assistance systems or recent game consoles. Future interaction will be embedded into smart environments offering the user to choose and to combine a heterogeneous set of interaction devices and modalities based on his preferences realizing an ubiquitous and multimodal access.

This framework enables the modeling and execution of multimodal interaction interfaces for the web based on ruby and implements a server-sided synchronisation of all connected modes and media. Currenlty the framework considers gestures, head movements, multi touch and the mouse as principle input modes. The priciple output media is a web application based on a rails frontend as well as sound support based on the SDL libraries.

Building this framework is an ongoing effort and it has to be pointed out that it serves to demonstrate scientific research results and is not targeted to we applied to serve productive systems as they are several limitations that need to be solved (maybe with your help?) like for instance multi-user support and authentification.  

The MINT core gem contains all basic AUI and CUI models as well as the basic infrastructure to create interactors and mappings. Please note that you need at least a CUI adapter gem to be able to actually run a system, e.g. the MINT-rails gem. But for initial experiements ist enough to follow the installation instructions of this document.

There is still no documentation for the framework, but a lot of articles about the concepts and theories of our approach have already been published and can be accessed from our project site http://www.multi-access.de .}
  s.email = [%q{Sebastian@Feuerstack.org}]
  s.executables = [%q{mint-aui}, %q{mint-cui-gfx}, %q{mint-juggernaut.sh}, %q{mint-tuplespace}]
  s.extra_rdoc_files = [%q{History.txt}, %q{Manifest.txt}, %q{PostInstall.txt}]
  s.files = [%q{Gemfile}, %q{Gemfile.lock}, %q{History.txt}, %q{MINT-core.gemspec}, %q{Manifest.txt}, %q{PostInstall.txt}, %q{README.rdoc}, %q{Rakefile}, %q{bin/mint-aui}, %q{bin/mint-cui-gfx}, %q{bin/mint-juggernaut.sh}, %q{bin/mint-tuplespace}, %q{lib/MINT-core.rb}, %q{lib/MINT-core/agent/agent.rb}, %q{lib/MINT-core/agent/aui.rb}, %q{lib/MINT-core/agent/auicontrol.rb}, %q{lib/MINT-core/agent/cui-gfx.rb}, %q{lib/MINT-core/agent/cuicontrol.rb}, %q{lib/MINT-core/mapping/complementary.rb}, %q{lib/MINT-core/mapping/mapping.rb}, %q{lib/MINT-core/mapping/on_state_change.rb}, %q{lib/MINT-core/mapping/sequential.rb}, %q{lib/MINT-core/model/aui/AIC.rb}, %q{lib/MINT-core/model/aui/AIINChoose.rb}, %q{lib/MINT-core/model/aui/AIMultiChoice.rb}, %q{lib/MINT-core/model/aui/AIMultiChoiceElement.rb}, %q{lib/MINT-core/model/aui/AIO.rb}, %q{lib/MINT-core/model/aui/AIOUTDiscrete.rb}, %q{lib/MINT-core/model/aui/AISingleChoice.rb}, %q{lib/MINT-core/model/aui/AISingleChoiceElement.rb}, %q{lib/MINT-core/model/aui/AISinglePresence.rb}, %q{lib/MINT-core/model/aui/aic.png}, %q{lib/MINT-core/model/aui/aic.scxml}, %q{lib/MINT-core/model/aui/aichoice.png}, %q{lib/MINT-core/model/aui/aio.png}, %q{lib/MINT-core/model/aui/aio.scxml}, %q{lib/MINT-core/model/aui/aisinglechoiceelement.png}, %q{lib/MINT-core/model/aui/aisinglechoiceelement.scxml}, %q{lib/MINT-core/model/aui/aisinglepresence.png}, %q{lib/MINT-core/model/aui/aisinglepresence.scxml}, %q{lib/MINT-core/model/aui/model.rb}, %q{lib/MINT-core/model/body/gesture_button.rb}, %q{lib/MINT-core/model/body/handgesture.rb}, %q{lib/MINT-core/model/body/head.png}, %q{lib/MINT-core/model/body/head.rb}, %q{lib/MINT-core/model/body/head.scxml}, %q{lib/MINT-core/model/cui/gfx/CIC.rb}, %q{lib/MINT-core/model/cui/gfx/CIO.rb}, %q{lib/MINT-core/model/cui/gfx/model.rb}, %q{lib/MINT-core/model/cui/gfx/screen.rb}, %q{lib/MINT-core/model/device/button.rb}, %q{lib/MINT-core/model/device/joypad.rb}, %q{lib/MINT-core/model/device/mouse.rb}, %q{lib/MINT-core/model/device/pointer.rb}, %q{lib/MINT-core/model/device/wheel.rb}, %q{lib/MINT-core/model/interactor.rb}, %q{lib/MINT-core/model/task.rb}, %q{lib/MINT-core/overrides/rinda.rb}, %q{script/console}, %q{script/destroy}, %q{script/generate}, %q{spec/AIC_spec.rb}, %q{spec/AISinglePresence_spec.rb}, %q{spec/MINT-core_spec.rb}, %q{spec/aio_agent_spec.rb}, %q{spec/aio_spec.rb}, %q{spec/aisinglechoice_spec.rb}, %q{spec/aisinglechoiceelement_spec.rb}, %q{spec/cio_spec.rb}, %q{spec/core_spec.rb}, %q{spec/music_spec.rb}, %q{spec/rcov.opts}, %q{spec/spec.opts}, %q{spec/spec_helper.rb}, %q{tasks/rspec.rake}, %q{.gemtest}]
  s.homepage = %q{http://www.multi-access.de}
  s.post_install_message = %q{PostInstall.txt}
  s.rdoc_options = [%q{--main}, %q{README.rdoc}]
  s.require_paths = [%q{lib}]
  s.rubyforge_project = %q{MINT-core}
  s.rubygems_version = %q{1.8.5}
  s.summary = %q{Multimodal systems realizing a combination of speech, gesture and graphical-driven interaction are getting part of our everyday life}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<dm-rinda-adapter>, ["~> 0.1.0"])
      s.add_runtime_dependency(%q<MINT-statemachine>, ["~> 1.2.3"])
      s.add_runtime_dependency(%q<MINT-scxml>, ["~> 1.0.0"])
      s.add_runtime_dependency(%q<cassowary>, ["~> 1.0.1"])
      s.add_runtime_dependency(%q<dm-core>, ["~> 0.10.2"])
      s.add_runtime_dependency(%q<dm-rinda-adapter>, ["~> 0.1.2"])
      s.add_runtime_dependency(%q<cassowary>, ["~> 1.0.1"])
      s.add_runtime_dependency(%q<eventmachine>, ["~> 0.12.10"])
      s.add_runtime_dependency(%q<rake>, ["= 0.9.2.2"])
      s.add_runtime_dependency(%q<rmagick>, ["~> 2.12.2"])
      s.add_runtime_dependency(%q<json>, ["~> 1.5.1"])
      s.add_runtime_dependency(%q<redis>, ["~> 2.2.1"])
      s.add_runtime_dependency(%q<dm-types>, ["~> 0.10.2"])
      s.add_development_dependency(%q<rspec>, ["= 1.3.1"])
      s.add_development_dependency(%q<newgem>, ["~> 1.5.3"])
      s.add_development_dependency(%q<rdoc>, ["~> 3.11"])
      s.add_development_dependency(%q<hoe>, ["~> 2.9"])
    else
      s.add_dependency(%q<dm-rinda-adapter>, ["~> 0.1.0"])
      s.add_dependency(%q<MINT-statemachine>, ["~> 1.2.3"])
      s.add_dependency(%q<MINT-scxml>, ["~> 1.0.0"])
      s.add_dependency(%q<cassowary>, ["~> 1.0.1"])
      s.add_dependency(%q<dm-core>, ["~> 0.10.2"])
      s.add_dependency(%q<dm-rinda-adapter>, ["~> 0.1.2"])
      s.add_dependency(%q<cassowary>, ["~> 1.0.1"])
      s.add_dependency(%q<eventmachine>, ["~> 0.12.10"])
      s.add_dependency(%q<rake>, ["= 0.9.2.2"])
      s.add_dependency(%q<rmagick>, ["~> 2.12.2"])
      s.add_dependency(%q<json>, ["~> 1.5.1"])
      s.add_dependency(%q<redis>, ["~> 2.2.1"])
      s.add_dependency(%q<dm-types>, ["~> 0.10.2"])
      s.add_dependency(%q<rspec>, ["= 1.3.1"])
      s.add_dependency(%q<newgem>, ["~> 1.5.3"])
      s.add_dependency(%q<rdoc>, ["~> 3.11"])
      s.add_dependency(%q<hoe>, ["~> 2.9"])
    end
  else
    s.add_dependency(%q<dm-rinda-adapter>, ["~> 0.1.0"])
    s.add_dependency(%q<MINT-statemachine>, ["~> 1.2.3"])
    s.add_dependency(%q<MINT-scxml>, ["~> 1.0.0"])
    s.add_dependency(%q<cassowary>, ["~> 1.0.1"])
    s.add_dependency(%q<dm-core>, ["~> 0.10.2"])
    s.add_dependency(%q<dm-rinda-adapter>, ["~> 0.1.2"])
    s.add_dependency(%q<cassowary>, ["~> 1.0.1"])
    s.add_dependency(%q<eventmachine>, ["~> 0.12.10"])
    s.add_dependency(%q<rake>, ["= 0.9.2.2"])
    s.add_dependency(%q<rmagick>, ["~> 2.12.2"])
    s.add_dependency(%q<json>, ["~> 1.5.1"])
    s.add_dependency(%q<redis>, ["~> 2.2.1"])
    s.add_dependency(%q<dm-types>, ["~> 0.10.2"])
    s.add_dependency(%q<rspec>, ["= 1.3.1"])
    s.add_dependency(%q<newgem>, ["~> 1.5.3"])
    s.add_dependency(%q<rdoc>, ["~> 3.11"])
    s.add_dependency(%q<hoe>, ["~> 2.9"])
  end
end
