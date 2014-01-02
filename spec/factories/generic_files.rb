FactoryGirl.define do

  factory :fixture, :class => GenericFile do
    factory :public_pdf do
      ignore do
        pid "vecnet:fixture-pdf"
       # user FactoryGirl.create(:user)
      end
      initialize_with { new(pid: pid, ) }
      read_groups ["public"]
      resource_type "Article"
      subject %w"lorem ipsum dolor sit amet"
      before(:create) do |gf|
        gf.batch=FactoryGirl.create(:collection)
        gf.apply_depositor_metadata("testuser")
        gf.title = "Fake Document Title"
        gf.label = "fake_document.pdf"
      end
    end
    factory :public_mp3 do
      ignore do
        pid "vecnet:fixture-mp3"
        #user FactoryGirl.create(:user, agreed_to_terms_of_service: true)
      end
      initialize_with { new(pid: pid) }
      subject %w"consectetur adipisicing elit"
      before(:create) do |gf|
        gf.batch=FactoryGirl.create(:collection)
        gf.apply_depositor_metadata("testuser")
        gf.inner_object.pid = "vecnet:fixture-mp3"
        gf.label = "Test Document MP3.mp3"
      end
      read_groups ["public"]
    end
    factory :public_wav do
      ignore do
        pid "vecnet:fixture-wav"
        #user FactoryGirl.create(:user, agreed_to_terms_of_service: true)
      end
      initialize_with { new(pid: pid) }
      resource_type ["Audio", "Dataset"]
      read_groups ["public"]
      subject %w"sed do eiusmod tempor incididunt ut labore"
      before(:create) do |gf|
        gf.batch=FactoryGirl.create(:collection)
        gf.apply_depositor_metadata("testuser")
        gf.label = "Fake Wav File.wav"
      end
    end

    factory :private_file do
      ignore do
        pid "vecnet:fixture-private"
        #user FactoryGirl.create(:user, agreed_to_terms_of_service: true)
      end
      initialize_with { new(pid: pid) }
      resource_type ["Article"]
      subject %w"sed do eiusmod tempor incididunt ut labore"
      before(:create) do |gf|
        gf.batch=FactoryGirl.create(:collection)
        gf.apply_depositor_metadata("testuser")
        gf.label = "Fake Private File"
      end
    end
  end

end