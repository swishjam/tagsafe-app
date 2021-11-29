module Admin
  class ObjectFlagsController < BaseController
    def show
      @flag = Flag.find(params[:flag_id])
      @object_flag = ObjectFlag.find(params[:id])
    end
    
    def new
      @flag = Flag.find(params[:flag_id])
    end

    def update
      @object_flag = ObjectFlag.find(params[:id])
      @object_flag.update(object_flag_params)
      display_success_banner("#{@object_flag.flag.name} flag for #{@object_flag.display_name} updated to #{@object_flag.value}")
      redirect_to admin_flag_object_flag_path(@object_flag.flag, @object_flag)
    end

    def create
      uid_prefix = params[:object_uid].split('_')[0]
      object = case uid_prefix
                when 'org'
                  Organization.find_by(uid: params[:object_uid])
                when 'dom'
                  Domain.find_by(uid: params[:object_uid])
                when 'tag'
                  Tag.find_by(uid: params[:object_uid])
                else
                  raise GenericTagSafeError, "Invalid object type #{uid_prefix}"
                end
      flag = Flag.find(params[:flag_id])
      object_flag = Flag.set_flag_for_object(object, flag.slug, params[:value])
      display_success_banner("#{flag.name} added to #{object_flag.display_name} with a value of #{params[:value]}")
      redirect_to admin_flag_path(flag)
    end

    def destroy
      @flag = Flag.find(params[:flag_id])
      @object_flag = ObjectFlag.find(params[:id])
      @object_flag.destroy!
      display_success_banner("#{@flag.name} removed from #{@object_flag.display_name}")
      redirect_to admin_flag_path(@flag)
    end

    private

    def object_flag_params
      params.require(:object_flag).permit(:value)
    end
  end
end