using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services;

namespace Deliverance.WebAPI.Controllers
{
    public class ExecutionCommandController : BaseReadController<ExecutionCommandResponse, ExecutionCommandSearchObject, IExecutionCommandService>
    {
        public ExecutionCommandController(IExecutionCommandService executionCommandService) : base(executionCommandService)
        {

        }
    }
}
