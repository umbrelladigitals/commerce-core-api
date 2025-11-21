# frozen_string_literal: true# frozen_string_literal: true



require 'rails_helper'require 'rails_helper'



RSpec.describe OrderStatusChangedJob, type: :job doRSpec.describe OrderStatusChangedJob, type: :job do

  let(:user) { create(:user, :dealer, email: 'dealer@example.com', name: 'John Doe') }  let(:user) { create(:user, :dealer, email: 'dealer@example.com', name: 'John Doe') }

  let(:order) { create(:order, user: user, status: :paid, tracking_number: 'TRK123') }  let(:order) { create(:order, user: user, status: :paid, tracking_number: 'TRK123') }

  let!(:template) { create(:notification_template, :order_paid) }  let(:template) { create(:notification_template, :order_paid) }

    

  describe '#perform' do  before do

    context 'when template exists' do    # Seed'deki template yoksa oluştur

      it 'sends notification' do    template

        expect {  end

          OrderStatusChangedJob.perform_now(order.id, 'cart', 'paid')  

        }.to change(NotificationLog, :count).by(1)  describe '#perform' do

      end    context 'when template exists' do

            it 'sends notification' do

      it 'uses correct template' do        expect {

        OrderStatusChangedJob.perform_now(order.id, 'cart', 'paid')          OrderStatusChangedJob.perform_now(order.id, 'cart', 'paid')

                }.to change(NotificationLog, :count).by(1)

        log = NotificationLog.last      end

        expect(log.notification_template).to eq(template)      

      end      it 'uses correct template' do

              OrderStatusChangedJob.perform_now(order.id, 'cart', 'paid')

      it 'sends to order user email' do        

        OrderStatusChangedJob.perform_now(order.id, 'cart', 'paid')        log = NotificationLog.last

                expect(log.notification_template).to eq(template)

        log = NotificationLog.last      end

        expect(log.recipient).to eq(user.email)      

      end      it 'sends to order user email' do

              OrderStatusChangedJob.perform_now(order.id, 'cart', 'paid')

      it 'replaces placeholders with order data' do        

        OrderStatusChangedJob.perform_now(order.id, 'cart', 'paid')        log = NotificationLog.last

                expect(log.recipient).to eq(user.email)

        log = NotificationLog.last      end

        rendered_body = log.payload['rendered_body']      

              it 'replaces placeholders with order data' do

        expect(rendered_body).to include(order.id.to_s)        OrderStatusChangedJob.perform_now(order.id, 'cart', 'paid')

        expect(rendered_body).to include(user.name)        

      end        log = NotificationLog.last

    end        rendered_body = log.payload['rendered_body']

            

    context 'when template does not exist' do        expect(rendered_body).to include(order.id.to_s)

      before { template.destroy }        expect(rendered_body).to include(user.name)

            end

      it 'logs warning and does not send notification' do    end

        expect(Rails.logger).to receive(:warn).with(/Template not found/)    

            context 'when template does not exist' do

        expect {      before { template.destroy }

          OrderStatusChangedJob.perform_now(order.id, 'cart', 'paid')      

        }.not_to change(NotificationLog, :count)      it 'logs warning and does not send notification' do

      end        expect(Rails.logger).to receive(:warn).with(/Template not found/)

    end        

            expect {

    context 'when user has no email' do          OrderStatusChangedJob.perform_now(order.id, 'cart', 'paid')

      before { user.update!(email: nil) }        }.not_to change(NotificationLog, :count)

            end

      it 'logs warning and does not send notification' do    end

        expect(Rails.logger).to receive(:warn).with(/User has no email/)    

            context 'when user has no email' do

        expect {      before { user.update!(email: nil) }

          OrderStatusChangedJob.perform_now(order.id, 'cart', 'paid')      

        }.not_to change(NotificationLog, :count)      it 'logs warning and does not send notification' do

      end        expect(Rails.logger).to receive(:warn).with(/User has no email/)

    end        

  end        expect {

end          OrderStatusChangedJob.perform_now(order.id, 'cart', 'paid')

        }.not_to change(NotificationLog, :count)
      end
    end
  end
endre 'rails_helper'

RSpec.describe OrderStatusChangedJob, type: :job do
  pending "add some examples to (or delete) #{__FILE__}"
end
