# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "MINT-core"
  s.version = "1.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Sebastian Feuerstack"]
  s.date = "2012-01-30"
  s.description = "Multimodal systems realizing a combination of speech, gesture and graphical-driven interaction are getting part of our everyday life.\n\nExamples are in-car assistance systems or recent game consoles. Future interaction will be embedded into smart environments offering the user to choose and to combine a heterogeneous set of interaction devices and modalities based on his preferences realizing an ubiquitous and multimodal access.\n\nThis framework enables the modeling and execution of multimodal interaction interfaces for the web based on ruby and implements a server-sided synchronisation of all connected modes and media. Currenlty the framework considers gestures, head movements, multi touch and the mouse as principle input modes. The priciple output media is a web application based on a rails frontend as well as sound support based on the SDL libraries.\n\nBuilding this framework is an ongoing effort and it has to be pointed out that it serves to demonstrate scientific research results and is not targeted to we applied to serve productive systems as they are several limitations that need to be solved (maybe with your help?) like for instance multi-user support and authentification.  \n\nThe MINT core gem contains all basic AUI and CUI models as well as the basic infrastructure to create interactors and mappings. Please note that you need at least a CUI adapter gem to be able to actually run a system, e.g. the MINT-rails gem. But for initial experiements ist enough to follow the installation instructions of this document.\n\nThere is still no documentation for the framework, but a lot of articles about the concepts and theories of our approach have already been published and can be accessed from our project site http://www.multi-access.de ."
  s.email = ["Sebastian@Feuerstack.org"]
  s.executables = ["mint-aui", "mint-cui-gfx", "mint-juggernaut.sh", "mint-tuplespace"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "PostInstall.txt"]
  s.files = ["Gemfile", "Gemfile.lock", "History.txt", "MINT-core.gemspec", "Manifest.txt", "PostInstall.txt", "README.rdoc", "Rakefile", "bin/mint-aui", "bin/mint-cui-gfx", "bin/mint-juggernaut.sh", "bin/mint-tuplespace", "lib/MINT-core.rb", "lib/MINT-core/agent/agent.rb", "lib/MINT-core/agent/aui.rb", "lib/MINT-core/agent/auicontrol.rb", "lib/MINT-core/agent/cui-gfx.rb", "lib/MINT-core/agent/cuicontrol.rb", "lib/MINT-core/mapping/complementary.rb", "lib/MINT-core/mapping/mapping.rb", "lib/MINT-core/mapping/on_state_change.rb", "lib/MINT-core/mapping/sequential.rb", "lib/MINT-core/model/aui/AIC.rb", "lib/MINT-core/model/aui/AIChoice.rb", "lib/MINT-core/model/aui/AIINChoose.rb", "lib/MINT-core/model/aui/AIMultiChoice.rb", "lib/MINT-core/model/aui/AIMultiChoiceElement.rb", "lib/MINT-core/model/aui/AIO.rb", "lib/MINT-core/model/aui/AIOUTDiscrete.rb", "lib/MINT-core/model/aui/AISingleChoice.rb", "lib/MINT-core/model/aui/AISingleChoiceElement.rb", "lib/MINT-core/model/aui/AISinglePresence.rb", "lib/MINT-core/model/aui/aic.png", "lib/MINT-core/model/aui/aic.scxml", "lib/MINT-core/model/aui/aichoice.png", "lib/MINT-core/model/aui/aichoice.scxml", "lib/MINT-core/model/aui/aio.png", "lib/MINT-core/model/aui/aio.scxml", "lib/MINT-core/model/aui/aisinglechoiceelement.png", "lib/MINT-core/model/aui/aisinglechoiceelement.scxml", "lib/MINT-core/model/aui/aisinglepresence.png", "lib/MINT-core/model/aui/aisinglepresence.scxml", "lib/MINT-core/model/aui/model.rb", "lib/MINT-core/model/body/gesture_button.rb", "lib/MINT-core/model/body/handgesture.rb", "lib/MINT-core/model/body/head.png", "lib/MINT-core/model/body/head.rb", "lib/MINT-core/model/body/head.scxml", "lib/MINT-core/model/cui/gfx/CIC.rb", "lib/MINT-core/model/cui/gfx/CIO.rb", "lib/MINT-core/model/cui/gfx/model.rb", "lib/MINT-core/model/cui/gfx/screen.rb", "lib/MINT-core/model/device/button.rb", "lib/MINT-core/model/device/joypad.rb", "lib/MINT-core/model/device/mouse.rb", "lib/MINT-core/model/device/pointer.rb", "lib/MINT-core/model/device/wheel.rb", "lib/MINT-core/model/interactor.rb", "lib/MINT-core/model/task.rb", "lib/MINT-core/overrides/rinda.rb", "script/console", "script/destroy", "script/generate", "spec/AIC_spec.rb", "spec/AISinglePresence_spec.rb", "spec/MINT-core_spec.rb", "spec/aio_agent_spec.rb", "spec/aio_spec.rb", "spec/aisinglechoice_spec.rb", "spec/aisinglechoiceelement_spec.rb", "spec/cio_spec.rb", "spec/core_spec.rb", "spec/music_spec.rb", "spec/rcov.opts", "spec/spec.opts", "spec/spec_helper.rb", "tasks/rspec.rake", ".gemtest"]
  s.homepage = "http://www.multi-access.de"
  s.post_install_message = "PostInstall.txt"
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "MINT-core"
  s.rubygems_version = "1.8.12"
  s.summary = "Multimodal systems realizing a combination of speech, gesture and graphical-driven interaction are getting part of our everyday life"

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
      s.add_runtime_dependency(%q<dm-serializer>, ["~> 0.10.2"])
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
      s.add_dependency(%q<dm-serializer>, ["~> 0.10.2"])
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
    s.add_dependency(%q<dm-serializer>, ["~> 0.10.2"])
    s.add_dependency(%q<rspec>, ["= 1.3.1"])
    s.add_dependency(%q<newgem>, ["~> 1.5.3"])
    s.add_dependency(%q<rdoc>, ["~> 3.11"])
    s.add_dependency(%q<hoe>, ["~> 2.9"])
  end
end
