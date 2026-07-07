Rails.application.config.to_prepare do
  MessagesController.class_eval do
    private

    def recommend_cocktail(decision = {})
      cocktail = fetch_cocktail_from_api(decision)

      if cocktail.present?
        @chat.update!(cocktail: cocktail)
        @assistant_message.update!(content: recommendation_text(cocktail, decision), cocktail: cocktail)
        replace_assistant_message
        broadcast_cocktail_card(cocktail)
        broadcast_glass_animation
      else
        @assistant_message.update!(
          content: "Je n'arrive pas à joindre une fiche cocktail fiable pour l'instant. Le bar est ouvert, mais le carnet de recettes fait semblant d'être mystérieux."
        )
        replace_assistant_message
      end
    end

    def fetch_cocktail_from_api(decision = {})
      mood = decision[:mood].presence || cocktail_mood
      tool = RecommendCocktailTool.new(user: current_user, chat: @chat)
      tried_names = []

      cocktail_candidate_groups(decision).each do |candidate_group|
        candidate_group.each do |candidate|
          next if tried_names.include?(candidate[:name].downcase)

          tried_names << candidate[:name].downcase
          result = tool.execute(cocktail_name: candidate[:name], mood: mood)
          Rails.logger.info "Bill cocktail fallback result: #{result.inspect}"

          next if result[:error].present?

          cocktail = current_user.cocktails.find_by(id: result[:cocktail_id])

          next if cocktail.blank?
          next if proposed_names_in_chat.include?(cocktail.name.downcase)
          next if existing_cocktail_names.include?(cocktail.name.downcase)
          next unless cocktail_respects_hard_constraints?(cocktail, decision)

          return cocktail
        end
      end

      nil
    end

    def cocktail_candidate_groups(decision = {})
      [
        ranked_cocktail_candidates(decision, require_included: true, strict_tags: true),
        ranked_cocktail_candidates(decision, require_included: false, strict_tags: true),
        ranked_cocktail_candidates(decision, require_included: false, strict_tags: false)
      ]
    end

    def ranked_cocktail_candidates(decision = {}, require_included:, strict_tags:)
      constraints = ingredient_constraints(decision)
      excluded_names = (proposed_names_in_chat + existing_cocktail_names).uniq
      selected_tags = mood_tags(decision)

      candidates = COCKTAIL_CATALOG.reject do |candidate|
        excluded_names.include?(candidate[:name].downcase) ||
          constraints[:excluded].intersect?(candidate[:ingredients]) ||
          (require_included && constraints[:included].any? { |ingredient| candidate[:ingredients].exclude?(ingredient) })
      end

      candidates = candidates.select { |candidate| candidate[:tags].include?("mocktail") } if wants_no_alcohol?(decision)
      candidates = candidates.reject { |candidate| candidate[:tags].include?("mocktail") } if alcohol_preference == :with
      candidates = candidates.select { |candidate| (candidate[:tags] & selected_tags).any? } if strict_tags && selected_tags.present?

      candidates.sort_by do |candidate|
        [
          -cocktail_candidate_score(candidate, selected_tags, constraints),
          candidate[:name]
        ]
      end.first(18)
    end

    def cocktail_candidate_score(candidate, selected_tags, constraints)
      tag_score = (candidate[:tags] & selected_tags).size * 5
      included_score = (candidate[:ingredients] & constraints[:included]).size * 4
      alcohol_score = alcohol_preference == :with && candidate[:ingredients].intersect?(LIQUOR_INGREDIENTS) ? 2 : 0
      mocktail_penalty = candidate[:tags].include?("mocktail") && alcohol_preference == :with ? -5 : 0

      tag_score + included_score + alcohol_score + mocktail_penalty
    end

    def cocktail_respects_hard_constraints?(cocktail, decision = {})
      constraints = ingredient_constraints(decision)
      ingredients_text = normalize_text("#{cocktail.name} #{cocktail.ingredients}")

      constraints[:excluded].none? { |ingredient| ingredient_present?(ingredients_text, ingredient) }
    end
  end
end
