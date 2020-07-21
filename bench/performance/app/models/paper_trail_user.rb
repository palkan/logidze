# frozen_string_literal: true

class PaperTrailUser < ApplicationRecord
  has_paper_trail

  def self.diff_from(ts)
    includes(:versions).map { |u| {"id" => u.id, "changes" => u.diff_from(ts)} }
  end

  def self.diff_from_joined(ts)
    eager_load(:versions).map { |u| {"id" => u.id, "changes" => u.diff_from(ts)} }
  end

  def diff_from(ts)
    changes = {}
    versions.each do |v|
      next if v.created_at < ts
      merge_changeset(changes, v.changeset)
    end
    changes
  end

  private

  def merge_changeset(acc, data)
    data.each do |k, v|
      unless acc.key?(k)
        acc[k] = {"old" => v[0]}
      end
      acc[k]["new"] = v[1]
    end
  end
end
