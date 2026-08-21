class CourseModule {
  final String id;
  final String stage;
  final String title;
  final String summary;
  final String trophyTitle;
  final List<String> exercises;

  const CourseModule({
    required this.id,
    required this.stage,
    required this.title,
    required this.summary,
    required this.trophyTitle,
    required this.exercises,
  });
}

const courseModules = <CourseModule>[
  CourseModule(
    id: 'focus',
    stage: 'Module 1',
    title: 'Focus & Engagement',
    summary: 'Build a dog that wants to work with you before adding speed or equipment.',
    trophyTitle: 'Focus First Mate',
    exercises: [
      'Reward voluntary eye contact and check-ins',
      'Practise short, exciting engagement games',
      'Finish while your dog still wants more',
    ],
  ),
  CourseModule(
    id: 'recall',
    stage: 'Module 2',
    title: 'Rapid Recall',
    summary: 'Create a fast, happy response back to the handler with very little hesitation.',
    trophyTitle: 'Rapid Recall Rookie',
    exercises: [
      'Short recall in a low-distraction area',
      'Increase distance gradually',
      'Add a mild distraction once the response is strong',
    ],
  ),
  CourseModule(
    id: 'tug',
    stage: 'Module 3',
    title: 'Toy & Tug Drive',
    summary: 'Build value in playing with the handler so rewards stay exciting around flyball.',
    trophyTitle: 'Tugboat Champion',
    exercises: [
      'Find the toy your dog values most',
      'Use short energetic tug games',
      'Practise switching between food and toy rewards',
    ],
  ),
  CourseModule(
    id: 'deadball',
    stage: 'Module 4',
    title: 'Dead Ball Retrieve',
    summary: 'Teach a confident pickup and a quick return with the ball.',
    trophyTitle: 'Dead Ball Deckhand',
    exercises: [
      'Pick up a stationary ball',
      'Return directly to the handler',
      'Build speed while keeping the retrieve clean',
    ],
  ),
  CourseModule(
    id: 'target',
    stage: 'Module 5',
    title: 'Target Foundations',
    summary: 'Introduce body awareness and targeting skills that will later support box work.',
    trophyTitle: 'Target Treasure',
    exercises: [
      'Introduce a target with calm repetitions',
      'Reward accurate foot placement',
      'Build a smooth turn away from the target',
    ],
  ),
  CourseModule(
    id: 'movement',
    stage: 'Module 6',
    title: 'Movement & Body Awareness',
    summary: 'Help your dog move confidently, control their body and work safely.',
    trophyTitle: 'Sea Legs',
    exercises: [
      'Slow controlled movement over safe ground poles',
      'Simple balance and body-position games',
      'Short confidence exercises on different surfaces',
    ],
  ),
  CourseModule(
    id: 'distractions',
    stage: 'Module 7',
    title: 'Working Around Distractions',
    summary: 'Keep connection with the handler while the world gets a little more exciting.',
    trophyTitle: 'Steady Shipmate',
    exercises: [
      'Repeat known skills around one mild distraction',
      'Reward choosing the handler over the distraction',
      'Increase difficulty slowly',
    ],
  ),
  CourseModule(
    id: 'flyballready',
    stage: 'Module 8',
    title: 'Pre-Flyball Ready',
    summary: 'Bring the foundation skills together before applying for an in-person beginners course.',
    trophyTitle: 'Ready for the Crew',
    exercises: [
      'Show confident engagement and recall',
      'Show a useful reward or toy game',
      'Show a clean retrieve or target exercise',
    ],
  ),
];
