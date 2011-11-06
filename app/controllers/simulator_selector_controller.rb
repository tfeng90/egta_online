module SimulatorSelectorController
  def create
    params[params[:controller].singularize] = params[params[:controller].singularize].merge(params[:selector])
    create!
  end

  def update
    params[params[:controller].singularize] = params[params[:controller].singularize].merge(params[:selector])
    update!
  end

  def update_parameters
    @simulator = Simulator.find(params[:simulator_id])
    respond_to do |format|
      format.js {render "simulator_selector/update_parameters"}
    end
  end
end