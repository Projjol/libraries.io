class Admin::GithubRepositoriesController < Admin::ApplicationController
  def show
    @github_repository = GithubRepository.find(params[:id])
  end

  def update
    @github_repository = GithubRepository.find(params[:id])
    if @github_repository.update_attributes(github_repository_params)
      @github_repository.update_all_info_async
      redirect_to github_repository_path(@github_repository.owner_name, @github_repository.project_name)
    else
      redirect_to admin_github_repository_path(@github_repository.id)
    end
  end

  def deprecate
    change(:deprecate!)
  end

  def unmaintain
    change(:unmaintain!)
  end

  def index
    if params[:language].present?
      @language = GithubRepository.language(params[:language].downcase).first.try(:language)
      raise ActiveRecord::RecordNotFound if @language.nil?
      scope = GithubRepository.language(@language)
    else
      scope = GithubRepository
    end

    @languages = GithubRepository.maintained.without_license.with_projects.group('github_repositories.language').count.sort_by(&:last).reverse.first(20)
    @github_repositories = scope.maintained.without_license.with_projects.order("COUNT(projects.id) DESC").group("github_repositories.id").paginate(page: params[:page])
  end

  def deprecated
    search('deprecated')
  end

  def unmaintained
    search('unmaintained')
  end

  private

  def github_repository_params
    params.require(:github_repository).permit(:license, :status)
  end

  def search(query)
    @search = GithubRepository.search(query, must_not: [
      terms: { "status" => ["Unmaintained","Active","Deprecated"] }
    ], sort: 'stargazers_count').paginate(page: params[:page])
    @github_repositories = @search.records
  end

  def change(method)
    @github_repository = GithubRepository.find(params[:id])
    @github_repository.send(method)
    @github_repository.update_all_info_async
    redirect_to github_repository_path(@github_repository.owner_name, @github_repository.project_name)
  end
end
