# frozen_string_literal: true

module Api
  module V1
    module Admin
      # Admin notları yönetimi
      # Yöneticiler sipariş, bayi, müşteri vb. hakkında not tutabilir
      class NotesController < ApplicationController
        before_action :authenticate_user!
        before_action :require_admin!
        before_action :set_note, only: [:show, :update, :destroy]
        
        # GET /api/v1/admin/notes
        # Tüm notları listele veya belirli bir kayda ait notları getir
        def index
          @notes = AdminNote.includes(:author, :related).recent
          
          # Filtreleme
          @notes = @notes.where(related_type: params[:related_type]) if params[:related_type].present?
          @notes = @notes.where(related_id: params[:related_id]) if params[:related_id].present?
          @notes = @notes.by_author(params[:author_id]) if params[:author_id].present?
          
          # Sayfalama
          page = params[:page] || 1
          @notes = @notes.page(page).per(20)
          
          render json: {
            data: @notes.map { |note| serialize_note(note) },
            meta: {
              current_page: @notes.current_page,
              total_pages: @notes.total_pages,
              total_count: @notes.total_count
            }
          }
        end
        
        # GET /api/v1/admin/notes/:id
        def show
          render json: {
            data: serialize_note(@note)
          }
        end
        
        # POST /api/v1/admin/notes
        def create
          @note = AdminNote.new(note_params)
          @note.author = current_user
          
          if @note.save
            render json: {
              message: 'Not başarıyla oluşturuldu',
              data: serialize_note(@note)
            }, status: :created
          else
            render json: {
              error: 'Not oluşturulamadı',
              details: @note.errors.full_messages
            }, status: :unprocessable_entity
          end
        end
        
        # PATCH /api/v1/admin/notes/:id
        def update
          if @note.update(note_params.except(:related_type, :related_id))
            render json: {
              message: 'Not güncellendi',
              data: serialize_note(@note)
            }
          else
            render json: {
              error: 'Not güncellenemedi',
              details: @note.errors.full_messages
            }, status: :unprocessable_entity
          end
        end
        
        # DELETE /api/v1/admin/notes/:id
        def destroy
          @note.destroy
          render json: { message: 'Not silindi' }
        end
        
        private
        
        def set_note
          @note = AdminNote.find(params[:id])
        end
        
        def note_params
          params.require(:note).permit(:note, :related_type, :related_id)
        end
        
        def serialize_note(note)
          {
            type: 'admin_notes',
            id: note.id.to_s,
            attributes: {
              note: note.note,
              related_type: note.related_type,
              related_id: note.related_id,
              author_name: note.author.name,
              author_email: note.author.email,
              created_at: note.created_at,
              updated_at: note.updated_at
            },
            relationships: {
              author: {
                data: { type: 'users', id: note.author_id.to_s }
              },
              related: {
                data: { type: note.related_type, id: note.related_id.to_s }
              }
            }
          }
        end
        
        def require_admin!
          unless current_user.admin?
            render json: { error: 'Yetkisiz erişim' }, status: :forbidden
          end
        end
      end
    end
  end
end
