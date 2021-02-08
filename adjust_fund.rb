@success = []
@failed = []
@skipped = []
def give_out_bonuses(filename, dry_run: true)
 total = 0
 File.open(filename) do |file|
   file.lazy.drop(1).each_slice(50) do |lines|
     chunks = CSV.parse(lines.join, headers: false)
     total += process_users(chunks, dry_run)
   end
 end
 Rails.logger.info "Disbursed #{total} to #{@success.length} users"
end
def process_users(chunks, dry_run)
 amount_disbursed = 0
 chunks.each do |users|
   uids.each do |user_id|
     user = User.find(user_id)
     referring_user = User.find(user.referred_by)
     next if @success.include?(user.id)
     if dry_run
       amount_disbursed += 150
       Rails.logger.info "Disbursing 150 to c2: #{user.id} and c1: #{referring_user.id}"
       next
     end
     if !user.active?
       @skipped << user.id
       next
     end
     if !user.referral_bonus_eligible
       user.referral_bonus_eligible = true
       user.save!
     end
     amount = Processing::ReferralBonusProcessor.new(referring_user, user, 100, "ADPD", 201)
     if amount.positive?
       @success << user.id
     else
       @failed << user.id
     end
   end
   Rails.logger.info "Disbursed #{amount_disbursed} so far"
 end
 amount_disbursed
end
