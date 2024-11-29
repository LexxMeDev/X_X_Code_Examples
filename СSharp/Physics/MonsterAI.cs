using System.Linq;
using Characters.AI.Bases;
using Characters.Among;
using Characters.Bases;
using Characters.Components;
using Controllers;
using DataStructures.Enums;
using DataStructures.Transfer.Models.Bases;
using DevAssistent.Core.Services.MessageServices;
using DevAssistent.Core.Services.MessageServices.Interfaces;
using DevAssistent.Helpers;
using MessageSystem;
using SPSoundManager.Base;
using UnityEngine;

namespace Characters.AI
{
    public class MonsterAI : BaseAIController, 
        IMessageSubscriber<Messages.GamePlay.Level.ReviveCharacter>
    {
        [Header("Monster")]
        [SerializeField] private float attackRecoveryTime;
        [SerializeField] private DamageTriggerController damageTriggerController;
        [SerializeField] private ExclamationController exclamationController;
        
        [Header("Animation")] 
        [SerializeField] private string waitingAnimTrigger;
        [SerializeField] private string attackHumanTrigger;
        [SerializeField] private string attackPlayerTrigger;

        private bool _isAttacking;
        private bool _isAttackPlayer;
        private bool _isPushed;
        private bool _isPushedProcced;

        protected override void Awake()
        {
            base.Awake();
            MessageService.Subscribe(this);
        }

        protected override void OnDisable()
        {
            base.OnDisable();
            _isAttacking = false;
            _isAttackPlayer = false;
        }

        protected override void OnDestroy()
        {
            base.OnDestroy();
            MessageService.Unsubscribe(this);
        }

        public void PlayRandomStepSound()
        {
            SoundManager.PlaySound("HuggyStep" + Random.Range(1, 5));
        }

        public void PlaySound(string SoundName)
        {
            SoundManager.PlaySound(SoundName);
        }

        private void Update()
        {
            if (StoppedAI)
            {
                if (AiState == AIState.Waiting) return;
                SetAiState(AIState.Waiting);
                if(!_isAttackPlayer) 
                    AgentAnimator.SetTrigger(waitingAnimTrigger);
                return;
            }

            if (_isPushed)
            {
                if (!_isPushedProcced)
                {
                    Vector3 pos = GetOptimalPointOnNavMesh();
                    SetDestination(pos);
                }
                _isPushedProcced = true;

                CheckMoveAnim();
                return;
            }

            var seeTargetsInAttackRange = CheckTargetsInAttackRange();
            if (seeTargetsInAttackRange != null && AiState != AIState.Chasing)
            {
                SetAiState(AIState.Chasing);
                var playerController = seeTargetsInAttackRange.GetComponent<CrewmatePlayerController>();
                if (playerController != null)
                    exclamationController.gameObject.SetActive(true);
            }
            else if (seeTargetsInAttackRange == null && AiState == AIState.Chasing)
                SetAiState(AIState.Waiting);

            if (seeTargetsInAttackRange != null)
            {
                var playerController = seeTargetsInAttackRange.GetComponent<CrewmatePlayerController>();
                if (playerController != null)
                    exclamationController.gameObject.SetActive(true);
                SetDestination(seeTargetsInAttackRange.transform.position);
            }

            var toAttack = FOV.canSee && FOV.visibleTargets.Count > 0 && CheckAttack();
            if (toAttack)
                Attack();

            if (AiState != AIState.Chasing && !_isAttacking && AiState != AIState.Wandering)
                SetAiState(AIState.Wandering, GetOptimalPointOnNavMesh());

            if (AiState != AIState.Chasing && !_isAttacking && Agent.enabled && !Agent.pathPending && Agent.stoppingDistance >= Agent.remainingDistance)
                SetDestination(GetOptimalPointOnNavMesh());

            CheckMoveAnim();
        }

        private BaseCharacterController CheckTargetsInAttackRange()
        {
            if (TargetCharacters.Count == 0) 
                return null;
            
            BaseCharacterController controller = null;
            var maxDistance = float.MaxValue;
            foreach (var checkCharacter in TargetCharacters)
            {
                var distance = Vector3.Distance(transform.position, checkCharacter.transform.position);
                if (distance > maxDistance) continue;
                
                controller = checkCharacter;
                maxDistance = distance;
            }

            if (controller == null)
                return null;
            
            var dirToTarget = (controller.transform.position - transform.position).normalized;
            if (Vector3.Angle(transform.forward, dirToTarget) < FOV.viewAngle / 2 && maxDistance <= AttackRange)
            {
                if (controller.TryGetComponent(out CrewmateAIController box))
                {
                    if(box.HumanBoxController.BoxIsActive || box.isInvisible)
                    {
                        return null;
                    }
                    else
                    {
                        return controller;
                    }
                }
                else
                {
                    return controller;
                }
            }
            
            return null;
        }
        
        public void GetPushed()
        {
            _isPushed = true;
            _isPushedProcced = false;

            CoroutineHelper.Delay(3f, () => {
                _isPushed = false;
            });
        }

        private bool CheckAttack()
        {
            var characters = damageTriggerController.Characters
                .Select(character => character.GetComponent<BaseCharacterController>())
                .ToList()
                .FindAll(character => character != null)
                .FindAll(character =>
                    character.isInvisible == false && character.HumanBoxController.BoxIsActive == false);
            
            if (_isAttacking || damageTriggerController.Characters.Count == 0)
                return false;

            var filteredCharacters = characters.Select(item => TargetCharacters.Contains(item)).ToList();
            if (filteredCharacters.Count == 0) 
                return false;
            
            _isAttacking = true;
            StartCoroutine(CoroutineHelper.DelayIEnumerator(attackRecoveryTime, () => _isAttacking = false));
            return true;
        }
        
        // Attack > Animation > Animation Event > DamageTriggerController.Kick();
        public override void Attack()
        {
            base.Attack();

            var toAttackCharacters = damageTriggerController.Characters.Where(character =>
            {
                if (character.TryGetComponent(out CrewmateAIController box))
                {
                    return !(box.HumanBoxController.BoxIsActive || box.isInvisible);
                }
                else
                {
                    return true;
                }
            });
            var players = toAttackCharacters
                .Select(character => character.GetComponent<CrewmatePlayerController>())
                .ToList()
                .FindAll(character => character != null);
            
            if (players.Count == 0)
            {
                AgentAnimator.SetTrigger(attackHumanTrigger);
                return;    
            }
            
            _isAttackPlayer = true;
            AgentAnimator.SetTrigger(attackPlayerTrigger);
        }

        public void OnMessage(Messages.GamePlay.Level.ReviveCharacter message)
        {
            _isAttackPlayer = false;
        }
    }
}