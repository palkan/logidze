# frozen_string_literal: true

describe "ignore log columns", :sequel do
  let(:user) { User.create }
  let!(:post) { NotLoggedPost.create(user: user) }

  describe "#update" do
    it "updates log_data" do
      expect do
        NotLoggedPost.with_pk!(post.id).update(title: "new")
      end.to change { Post.with_pk!(post.id).log_data.version }.by(1)
    end
  end

  describe "#log_data" do
    context "when model is configured with has_logidze(ignore_log_data: true)" do
      context "with default scope" do
        subject { NotLoggedPost.with_pk!(post.id) }

        it "loads data from DB" do
          expect(subject.reload_log_data).not_to be_nil
          expect(subject.reload_log_data).to be_a(Logidze::History)
        end
      end

      context ".with_log_data" do
        subject { NotLoggedPost.with_log_data.with_pk!(post.id) }

        it "loads log_data" do
          expect(subject.log_data).not_to be_nil
          expect(subject.log_data).to be_a(Logidze::History)
        end
      end

      describe ".with_log_data and custom select" do
        subject do
          NotLoggedPost.dataset.select(:title, :id, :active).with_log_data.with_pk!(
            post.id
          )
        end

        it "loads log_data" do
          expect(subject.log_data).not_to be_nil
          expect(subject.log_data).to be_a(Logidze::History)
        end
      end
    end
  end
end
