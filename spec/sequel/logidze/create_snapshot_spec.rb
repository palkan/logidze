# frozen_string_literal: true

describe "create logidze snapshot", :sequel do
  let(:now) { Time.local(1989, 7, 10, 18, 23, 33) }
  let(:user) do
    Logidze.without_logging do
      User.create(
        time: now, name: "test", age: 10, active: false, extra: {gender: "X"}.to_json
      )
    end
  end

  describe "#create_logidze_snapshot!" do
    specify "without arguments" do
      expect(user.log_data).to be_nil

      user.create_logidze_snapshot!

      expect(user.log_data).not_to be_nil
      expect(user.log_data.version).to eq 1
      expect(Time.at(user.log_data.current_version.time / 1000) - now).to be > 1.year
      expect(user.log_data.current_version.changes)
        .to include({
          "name" => "test",
          "age" => 10,
          "active" => false,
          "extra" => '{"gender": "X"}'
        })
    end

    specify "timestamp column" do
      expect(user.log_data).to be_nil

      user.create_logidze_snapshot!(timestamp: :time)

      expect(user.log_data).not_to be_nil
      expect(user.log_data.version).to eq 1
      expect(user.log_data.current_version.time).to eq(now.to_i * 1_000)
    end

    specify "columns filtering: only" do
      expect(user.log_data).to be_nil

      user.create_logidze_snapshot!(only: %w[name age])

      expect(user.log_data).not_to be_nil
      expect(user.log_data.version).to eq 1
      expect(user.log_data.current_version.changes).to eq({"name" => "test", "age" => 10})
    end

    specify "columns filtering: except" do
      expect(user.log_data).to be_nil

      user.create_logidze_snapshot!(except: %w[age])

      expect(user.log_data).not_to be_nil
      expect(user.log_data.version).to eq 1
      expect(user.log_data.current_version.changes.keys).to include("name", "active")
      expect(user.log_data.current_version.changes.keys).not_to include("age")
    end
  end

  describe ".create_logidze_snapshot" do
    specify do
      expect(user.log_data).to be_nil

      User.where(id: user.id)
        .create_logidze_snapshot(timestamp: :time, only: %w[name age])

      user.reload

      expect(user.log_data).not_to be_nil
      expect(user.log_data.version).to eq 1
      expect(user.log_data.current_version.time).to eq(now.to_i * 1_000)
      expect(user.log_data.current_version.changes).to eq({"name" => "test", "age" => 10})
    end
  end
end
