class Release < ActiveRecord::Base
  attr_accessible :accounts, :accounts_extra, :addons,
    :date, :help, :mysageone,
    :notes, :payroll, :status, :coordinator,
    :collaborate, :accountant_edition, :accounts_production, :sageone_corp_tax_uk

  has_one :release_note

  validates_presence_of :date
  before_save :set_coordinator

  paginates_per 10

  scope :search_filter, lambda { |search_terms|
    return nil if search_terms.blank?
    search_terms = "%#{search_terms}%"
    where('release_notes.release_notes LIKE ? OR releases.notes LIKE ?', search_terms, search_terms).joins(:release_note)
  }

  def self.repositories
    ['mysageone', 'accountant_edition', 'accounts', 'accounts_extra',
        'addons', 'payroll', 'collaborate', 'accounts_production', 'sageone_corp_tax_uk', 'help']
  end

  def self.version(app, release)
    if release.present?
      if release[app].present?
        release[app]
      else
        @date = release.date
        where("#{app} != '' AND date <= ?", @date).pluck(app).sort_by{ |a| a.split('.').map(&:to_i) }.last || '-'
      end
    end
  end

  def self.last_release
    self.where("date < '#{Date.today.strftime('%Y-%m-%d')}'").order('date').last
  end

  def self.next_release
    self.where("date >= '#{Date.today.strftime('%Y-%m-%d')}'").order('date').first
  end

  def set_coordinator
    self.coordinator = 'Russell Craxford' if self.coordinator.blank?
  end

  def self.sop_version(repo, version)
    begin
      sop_version = Octokit.contents("Sage/#{repo}", :path => 'SOP_VERSION', :ref => "v#{version}.rc1").content
      Base64.decode64(sop_version)
    rescue
      "?"
    end
  end



end
