require "acceptance_helper"

describe "Logidze triggers", :db do
	include_context "cleanup migrations"

	before(:all) do
		Dir.chdir("spec/dummy") do
			successfully "rails generate logidze:install"
			successfully "rails generate logidze:model post"
			successfully "rake db:migrate"
		end
	end

	let(:params) { { title: 'Triggers', rating: 10, active: false } }

	describe "insert" do
		let(:post) { Post.create!(params).reload }

		it "creates initial version", :aggregate_failures do
			expect(post.log_version).to eq 1
			expect(post.log_history.size).to eq 1
		end
	end

	describe "update" do
		before(:all) { @post = Post.create! }
		after(:all) { @post.destroy! }

		let(:post) { @post.reload }

		it "creates new version", :aggregate_failures do
			post.update!(params)
			expect(post.reload.log_version).to eq 2
			expect(post.log_history.size).to eq 2
		end

		it "creates several versions", :aggregate_failures do
			post.update!(params)
			post.update!(rating: 0)
			expect(post.reload.log_version).to eq 3

			Post.where(id: post.id).update_all(active: true)
			expect(post.reload.log_version).to eq 4
		end

		it "doesn't create new version if values not changed", :aggregate_failures do
			Post.where(id: post.id).update_all(rating: nil)
			expect(post.reload.log_version).to eq 1
			expect(post.log_history.size).to eq 1
		end
	end

	describe "undo/redo" do
		before(:all) { @post = Post.create!(title: 'Triggers', rating: 10) }
		after(:all) { @post.destroy! }

		let(:post) { @post.reload }

		it "undo and redo" do
			post.update!(rating: 5)
			post.update!(title: 'Good Triggers')
			
			expect(post.reload.log_version).to eq 3
			expect(post.log_history.size).to eq 3

			post.undo!
			expect(post.reload.log_version).to eq 2
			expect(post.log_history.size).to eq 3
			expect(post.title).to eq 'Triggers'
			expect(post.rating).to eq 5

			post.undo!
			expect(post.reload.log_version).to eq 1
			expect(post.log_history.size).to eq 3
			expect(post.title).to eq 'Triggers'
			expect(post.rating).to eq 10

			post.redo!
			expect(post.reload.log_version).to eq 2
			expect(post.log_history.size).to eq 3
			expect(post.title).to eq 'Triggers'
			expect(post.rating).to eq 5

			post.redo!
			expect(post.reload.log_version).to eq 3
			expect(post.log_history.size).to eq 3
			expect(post.title).to eq 'Good Triggers'
			expect(post.rating).to eq 5
		end
	end
end
