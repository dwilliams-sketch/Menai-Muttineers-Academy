class LessonDefinition {
  final String id;
  final String title;
  final String summary;

  const LessonDefinition({
    required this.id,
    required this.title,
    required this.summary,
  });
}

class CourseModule {
  final String id;
  final String stage;
  final String title;
  final String summary;
  final String trophyTitle;
  final String artKey;
  final String assessmentText;
  final List<LessonDefinition> lessons;

  const CourseModule({
    required this.id,
    required this.stage,
    required this.title,
    required this.summary,
    required this.trophyTitle,
    required this.artKey,
    required this.assessmentText,
    required this.lessons,
  });
}

class TrophyDefinition {
  final String id;
  final String title;
  final String category;
  final String description;
  final String artKey;

  const TrophyDefinition({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.artKey,
  });
}

const courseModules = <CourseModule>[
  CourseModule(
    id: 'focus',
    stage: 'Key Skill 1',
    title: 'Focus & Engagement',
    summary: 'Build a dog that chooses you, enjoys working with you and can switch into training mode happily.',
    trophyTitle: 'Focus First Mate',
    artKey: 'focus',
    assessmentText: 'Show your dog choosing to engage with you, following your movement and staying connected around a mild distraction.',
    lessons: [
      LessonDefinition(id: 'focus_1', title: 'What Engagement Looks Like', summary: 'Learn what useful engagement looks like before asking for formal behaviour.'),
      LessonDefinition(id: 'focus_2', title: 'Reward Markers & Timing', summary: 'Use clear timing so your dog understands exactly what earned the reward.'),
      LessonDefinition(id: 'focus_3', title: 'Voluntary Check-Ins', summary: 'Reward your dog for choosing to look back and reconnect with you.'),
      LessonDefinition(id: 'focus_4', title: 'Follow Me', summary: 'Build value in moving with the handler using short, lively games.'),
      LessonDefinition(id: 'focus_5', title: 'Switching Rewards', summary: 'Practise moving smoothly between food, toys and praise.'),
      LessonDefinition(id: 'focus_6', title: 'Focus Around Distractions', summary: 'Take the skill into a slightly busier setting without making it too hard.'),
    ],
  ),
  CourseModule(
    id: 'recall',
    stage: 'Key Skill 2',
    title: 'Rapid Recall',
    summary: 'Create a fast, happy response back to the handler with very little hesitation.',
    trophyTitle: 'Rapid Recall Rookie',
    artKey: 'recall',
    assessmentText: 'Show a quick, enthusiastic recall from a useful distance with a clean reward at the handler.',
    lessons: [
      LessonDefinition(id: 'recall_1', title: 'Recall Foundations', summary: 'Set up short, easy recalls where success is almost guaranteed.'),
      LessonDefinition(id: 'recall_2', title: 'Name Response', summary: 'Build a sharp response to the dog’s name before adding distance.'),
      LessonDefinition(id: 'recall_3', title: 'Reward Placement', summary: 'Use reward position to bring your dog right back to you.'),
      LessonDefinition(id: 'recall_4', title: 'Restrained Recall', summary: 'Add excitement and speed with a safe restrained release.'),
      LessonDefinition(id: 'recall_5', title: 'Adding Distance', summary: 'Increase the run gradually without losing enthusiasm.'),
      LessonDefinition(id: 'recall_6', title: 'Adding Distractions', summary: 'Practise around mild distractions while keeping success high.'),
      LessonDefinition(id: 'recall_7', title: 'Speed & Clean Finish', summary: 'Bring the whole recall together with speed and a useful finish.'),
    ],
  ),
  CourseModule(
    id: 'tug',
    stage: 'Key Skill 3',
    title: 'Toy & Tug Drive',
    summary: 'Build value in playing with the handler so rewards remain exciting around flyball.',
    trophyTitle: 'Tugboat Champion',
    artKey: 'tug',
    assessmentText: 'Show your dog choosing to play, tugging confidently and re-engaging after the toy is released.',
    lessons: [
      LessonDefinition(id: 'tug_1', title: 'Find the Best Reward', summary: 'Work out which toy and style of play your dog really values.'),
      LessonDefinition(id: 'tug_2', title: 'Invitation to Play', summary: 'Make the handler part of the fun rather than simply presenting a toy.'),
      LessonDefinition(id: 'tug_3', title: 'Safe Tug Mechanics', summary: 'Keep tugging controlled, comfortable and suitable for the individual dog.'),
      LessonDefinition(id: 'tug_4', title: 'Release & Re-Engage', summary: 'Teach that releasing the toy does not mean the game is over.'),
      LessonDefinition(id: 'tug_5', title: 'Food to Toy Switching', summary: 'Move between different rewards without losing drive.'),
      LessonDefinition(id: 'tug_6', title: 'Bring the Toy Back', summary: 'Encourage the dog to return to the handler to restart the game.'),
    ],
  ),
  CourseModule(
    id: 'deadball',
    stage: 'Key Skill 4',
    title: 'Dead Ball Retrieve',
    summary: 'Teach a confident stationary ball pickup and a quick return to the handler.',
    trophyTitle: 'Dead Ball Deckhand',
    artKey: 'deadball',
    assessmentText: 'Show a confident pickup of a stationary ball and a direct, enthusiastic return to the handler.',
    lessons: [
      LessonDefinition(id: 'deadball_1', title: 'Build Value in the Ball', summary: 'Make the ball worth finding and picking up without creating conflict.'),
      LessonDefinition(id: 'deadball_2', title: 'Stationary Pickup', summary: 'Teach a clean pickup from a ball placed on the ground.'),
      LessonDefinition(id: 'deadball_3', title: 'Turn Back to the Handler', summary: 'Reward the first movement back towards you after pickup.'),
      LessonDefinition(id: 'deadball_4', title: 'Deliver Close', summary: 'Build a useful return that finishes close enough to reward well.'),
      LessonDefinition(id: 'deadball_5', title: 'Add Distance', summary: 'Increase distance without losing the quality of the pickup or return.'),
      LessonDefinition(id: 'deadball_6', title: 'Add Speed', summary: 'Create more urgency while keeping the retrieve tidy.'),
      LessonDefinition(id: 'deadball_7', title: 'Different Places', summary: 'Generalise the skill to new surfaces and mild distractions.'),
    ],
  ),
  CourseModule(
    id: 'target',
    stage: 'Key Skill 5',
    title: 'Target Foundations',
    summary: 'Introduce body awareness and targeting skills that will later support safe box work.',
    trophyTitle: 'Target Treasure',
    artKey: 'target',
    assessmentText: 'Show a confident drive to the target, accurate body placement and a smooth turn away for reward.',
    lessons: [
      LessonDefinition(id: 'target_1', title: 'Meet the Target', summary: 'Introduce the target calmly and reward confident interaction.'),
      LessonDefinition(id: 'target_2', title: 'Accurate Foot Placement', summary: 'Build awareness of where the dog is placing their feet.'),
      LessonDefinition(id: 'target_3', title: 'Drive to the Target', summary: 'Add controlled forward movement towards the target.'),
      LessonDefinition(id: 'target_4', title: 'Turn Away', summary: 'Shape a smooth turn away from the target rather than stopping on it.'),
      LessonDefinition(id: 'target_5', title: 'Reward Placement', summary: 'Use reward position to support a clean, efficient movement pattern.'),
      LessonDefinition(id: 'target_6', title: 'Build Consistency', summary: 'Repeat the skill from different starting points without rushing.'),
    ],
  ),
  CourseModule(
    id: 'movement',
    stage: 'Key Skill 6',
    title: 'Movement & Body Awareness',
    summary: 'Help your dog move confidently, understand their body and build safe foundations for future flyball work.',
    trophyTitle: 'Sea Legs',
    artKey: 'movement',
    assessmentText: 'Show calm body-awareness exercises, controlled movement and confidence on safe, suitable surfaces.',
    lessons: [
      LessonDefinition(id: 'movement_1', title: 'Safe Warm-Up & Surfaces', summary: 'Choose sensible surfaces and prepare the dog before body-awareness work.'),
      LessonDefinition(id: 'movement_2', title: 'Slow Pole Work', summary: 'Use low, safe poles to encourage careful foot placement.'),
      LessonDefinition(id: 'movement_3', title: 'Rear-End Awareness', summary: 'Help the dog understand and control movement of the back feet.'),
      LessonDefinition(id: 'movement_4', title: 'Balance & Weight Shift', summary: 'Build controlled movement without using high-impact exercises.'),
      LessonDefinition(id: 'movement_5', title: 'Wraps & Turns', summary: 'Practise comfortable turns in both directions.'),
      LessonDefinition(id: 'movement_6', title: 'Controlled Speed', summary: 'Add a little more pace while keeping the dog balanced and confident.'),
    ],
  ),
  CourseModule(
    id: 'distractions',
    stage: 'Key Skill 7',
    title: 'Working Around Distractions',
    summary: 'Keep connection with the handler while the world becomes a little more exciting.',
    trophyTitle: 'Steady Shipmate',
    artKey: 'distractions',
    assessmentText: 'Show a known skill around a mild distraction, with the dog able to reconnect quickly with the handler.',
    lessons: [
      LessonDefinition(id: 'distractions_1', title: 'Know the Threshold', summary: 'Learn when your dog can still think and when the environment is too difficult.'),
      LessonDefinition(id: 'distractions_2', title: 'Start with Easy Distractions', summary: 'Practise a known skill while something mildly interesting is nearby.'),
      LessonDefinition(id: 'distractions_3', title: 'Reward Good Choices', summary: 'Pay the dog well for choosing the handler over the distraction.'),
      LessonDefinition(id: 'distractions_4', title: 'Movement Around You', summary: 'Build confidence while people or dogs move at a sensible distance.'),
      LessonDefinition(id: 'distractions_5', title: 'Reset & Recover', summary: 'Learn how to calmly reset when attention disappears.'),
    ],
  ),
  CourseModule(
    id: 'flyballready',
    stage: 'Key Skill 8',
    title: 'Pre-Flyball Ready',
    summary: 'Bring the foundation skills together before applying for an in-person beginners course.',
    trophyTitle: 'Ready for the Crew',
    artKey: 'ready',
    assessmentText: 'Submit one final video showing a selection of your best foundation skills. A trainer will check that you and your dog are ready for the next stage.',
    lessons: [
      LessonDefinition(id: 'ready_1', title: 'Putting Skills Together', summary: 'Link simple skills without turning the session into a long drill.'),
      LessonDefinition(id: 'ready_2', title: 'Recall into Reward', summary: 'Show a fast return that flows straight into the dog’s preferred reward.'),
      LessonDefinition(id: 'ready_3', title: 'Retrieve & Return', summary: 'Combine a useful pickup with a direct return.'),
      LessonDefinition(id: 'ready_4', title: 'Target & Turn', summary: 'Show the body-awareness and target foundations learned earlier.'),
      LessonDefinition(id: 'ready_5', title: 'Low-Impact Movement', summary: 'Show confident movement suitable for the dog’s age and ability.'),
      LessonDefinition(id: 'ready_6', title: 'Work Near a Distraction', summary: 'Demonstrate that the dog can reconnect with you when something else is happening.'),
      LessonDefinition(id: 'ready_7', title: 'Handler Skills', summary: 'Check reward timing, clear cues and short positive sessions.'),
      LessonDefinition(id: 'ready_8', title: 'Assessment Preparation', summary: 'Choose short clips that clearly show what you and your dog can do.'),
    ],
  ),
];

const trophyCatalog = <TrophyDefinition>[
  TrophyDefinition(id: 'focus', title: 'Focus First Mate', category: 'Skill Trophies', description: 'Passed the Focus & Engagement assessment.', artKey: 'focus'),
  TrophyDefinition(id: 'recall', title: 'Rapid Recall Rookie', category: 'Skill Trophies', description: 'Passed the Rapid Recall assessment.', artKey: 'recall'),
  TrophyDefinition(id: 'tug', title: 'Tugboat Champion', category: 'Skill Trophies', description: 'Passed the Toy & Tug Drive assessment.', artKey: 'tug'),
  TrophyDefinition(id: 'deadball', title: 'Dead Ball Deckhand', category: 'Skill Trophies', description: 'Passed the Dead Ball Retrieve assessment.', artKey: 'deadball'),
  TrophyDefinition(id: 'target', title: 'Target Treasure', category: 'Skill Trophies', description: 'Passed the Target Foundations assessment.', artKey: 'target'),
  TrophyDefinition(id: 'movement', title: 'Sea Legs', category: 'Skill Trophies', description: 'Passed the Movement & Body Awareness assessment.', artKey: 'movement'),
  TrophyDefinition(id: 'distractions', title: 'Steady Shipmate', category: 'Skill Trophies', description: 'Passed the Working Around Distractions assessment.', artKey: 'distractions'),
  TrophyDefinition(id: 'flyballready', title: 'Ready for the Crew', category: 'Skill Trophies', description: 'Passed the final Pre-Flyball Ready assessment.', artKey: 'ready'),
  TrophyDefinition(id: 'first_login', title: 'First Steps Aboard', category: 'Milestone Trophies', description: 'Logged into the Academy for the first time.', artKey: 'login'),
  TrophyDefinition(id: 'streak_7', title: 'Seven Days Aboard', category: 'Milestone Trophies', description: 'Logged in for 7 days in a row.', artKey: 'streak7'),
  TrophyDefinition(id: 'streak_14', title: 'Sea Legs Streak', category: 'Milestone Trophies', description: 'Logged in for 14 days in a row.', artKey: 'streak14'),
  TrophyDefinition(id: 'streak_30', title: 'Month on Deck', category: 'Milestone Trophies', description: 'Logged in for 30 days in a row.', artKey: 'streak30'),
  TrophyDefinition(id: 'first_lesson', title: 'First Lesson Logged', category: 'Milestone Trophies', description: 'Completed the first Academy lesson.', artKey: 'lesson'),
  TrophyDefinition(id: 'first_assessment', title: 'Brave Enough to Be Judged', category: 'Milestone Trophies', description: 'Submitted the first skill assessment.', artKey: 'assessment'),
  TrophyDefinition(id: 'first_skill', title: 'First Skill Mastered', category: 'Milestone Trophies', description: 'Earned the first trainer-verified skill trophy.', artKey: 'firstskill'),
  TrophyDefinition(id: 'birthday', title: 'Birthday Buccaneer', category: 'Special Trophies', description: 'A special Academy trophy for the dog’s birthday.', artKey: 'birthday'),
];
