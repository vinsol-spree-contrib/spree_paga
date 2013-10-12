Spree::Core::Engine.config.to_prepare do
  if Spree.user_class
    Spree.user_class.class_eval do

      def last_incomplete_spree_order
        spree_orders.incomplete.not_pending.order('created_at DESC').first
      end
    end
  end
end
